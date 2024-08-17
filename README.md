# Faviconic

Fetch a favicon from a URL, with multiple fallbacks.

**Full online documentation is available [here](https://hexdocs.pm/faviconic/Faviconic.html).**

**You can find the package on Hex [here](https://hex.pm/packages/faviconic).**

For `example.com` it will first try `example.com/favicon.ico`, then it will try to find the icon file path in the HTML, and if it does. If both fail, then it will try getting an icon from Duckduckgo and Google.


## To use

``` elixir
case Faviconic.fetch("google.com") do
  {:ok, image} -> image # image itself is returned
  {:error, error_message} -> IO.inspect(error_message)
end
```

``` elixir
case Faviconic.get("google.com") do
  {:ok, url} -> url # icon URL is returned
  {:error, error_message} -> IO.inspect(error_message)
end
```

---

MIT License

Copyright 2022 Bonfire Networks

Copyright 2018 Zak Miller (author of the library Faviconic was forked from: https://github.com/ZakMiller/fetch-favicon)
