defmodule Faviconic.SSRFTest do
  @moduledoc """
  Faviconic fetches URLs that come from untrusted input (a page URL, or an icon link found in a fetched page), so it must never reach a private or loopback address, on any hop.

  The targets are real `Bypass` servers on loopback: a refusal is proven by the server never being hit, and the positive cases fetch the same kind of target once its `host:port` is allowlisted. `ReqSSRF` has its own tests for address ranges and notations, so these only check that the check runs on each of Faviconic's requests, and that the allowlist doesn't switch it off for other hosts or later hops.
  """
  use ExUnit.Case, async: false

  @png <<137, 80, 78, 71, 13, 10, 26, 10>> <> :binary.copy(<<0>>, 64)

  setup do
    {:ok, bypass: Bypass.open()}
  end

  defp url(bypass, path), do: "http://127.0.0.1:#{bypass.port}#{path}"

  defp allow!(bypasses),
    do: Process.put(:ssrf_allow_hosts, Enum.map(List.wrap(bypasses), &"127.0.0.1:#{&1.port}"))

  defp serve(bypass, method \\ "GET", path, fun) do
    test_pid = self()

    Bypass.stub(bypass, method, path, fn conn ->
      send(test_pid, {:hit, bypass.port, path})
      fun.(conn)
    end)
  end

  defp serve_png(bypass, path, body \\ @png) do
    serve(bypass, path, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("image/png", nil)
      |> Plug.Conn.resp(200, body)
    end)
  end

  # once `/favicon.ico` fails, Faviconic falls back to looking for an icon link in the page itself
  defp no_page(bypass), do: Bypass.stub(bypass, "GET", "/", &Plug.Conn.resp(&1, 404, ""))

  # A refused fetch falls back to the third-party icon services, so the result can't show whether the target was refused: only the target's own hits can.
  defp refute_hit(bypass) do
    port = bypass.port
    refute_receive {:hit, ^port, _}, 300
  end

  test "an allowlisted host is fetched", %{bypass: bypass} do
    serve_png(bypass, "/favicon.ico")
    allow!(bypass)

    assert {:ok, @png} = Faviconic.fetch(url(bypass, "/"))
    assert_receive {:hit, _, "/favicon.ico"}
  end

  test "a loopback address is never fetched", %{bypass: bypass} do
    serve_png(bypass, "/favicon.ico")

    Faviconic.fetch(url(bypass, "/"))
    refute_hit(bypass)
  end

  test "the allowlist covers one port, not the whole host", %{bypass: bypass} do
    other = Bypass.open()
    serve_png(other, "/favicon.ico")
    allow!(bypass)

    Faviconic.fetch(url(other, "/"))
    refute_hit(other)
  end

  test "a redirect from an allowlisted host to a private one is refused", %{bypass: bypass} do
    target = Bypass.open()
    serve_png(target, "/favicon.ico")

    serve(bypass, "/favicon.ico", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("location", url(target, "/favicon.ico"))
      |> Plug.Conn.resp(302, "")
    end)

    no_page(bypass)
    allow!(bypass)

    Faviconic.fetch(url(bypass, "/"))
    assert_receive {:hit, _, "/favicon.ico"}
    refute_hit(target)
  end

  describe "an icon link in a fetched page" do
    test "is fetched when its host is allowlisted", %{bypass: bypass} do
      serve_png(bypass, "/icon.png")
      allow!(bypass)
      html = ~s(<link rel="icon" href="#{url(bypass, "/icon.png")}">)

      assert {:ok, @png} = Faviconic.find("https://example.com/", html, true)
      assert_receive {:hit, _, "/icon.png"}
    end

    test "can't point the server at a private address", %{bypass: bypass} do
      serve_png(bypass, "/icon.png")
      serve(bypass, "HEAD", "/icon.png", &Plug.Conn.resp(&1, 200, ""))
      html = ~s(<link rel="icon" href="#{url(bypass, "/icon.png")}">)

      Faviconic.find("https://example.com/", html, true)
      Faviconic.find("https://example.com/", html, false)
      refute_hit(bypass)
    end
  end

  test "a body over the size limit is not returned", %{bypass: bypass} do
    big = @png <> :binary.copy(<<0>>, 2_000)
    serve_png(bypass, "/favicon.ico", big)
    no_page(bypass)
    allow!(bypass)
    Process.put(:faviconic_max_bytes, 1_000)

    refute Faviconic.fetch(url(bypass, "/")) == {:ok, big}
    assert_receive {:hit, _, "/favicon.ico"}
  end
end
