# Faviconic

Fetch a favicon from a URL, with multiple fallbacks.

**Full online documentation is available [here](https://hexdocs.pm/faviconic/Faviconic.html).**

**You can find the package on Hex [here](https://hex.pm/packages/faviconic).**

For `example.com` it will first try `example.com/favicon.ico`, then it will try to find the icon file path in the HTML, and if it does, try to fetch that icon. If both fail, then it will query `https://www.google.com/s2/favicons?domain=example.com`

The image itself is returned.

## To use

``` elixir
case Faviconic.fetch("google.com") do
  {:ok, image} -> use_image(image)
  {:error, error_message} -> use_error(error_message)
end
```

---

MIT License

Copyright 2022 Bonfire Networks
Copyright 2018 Zak Miller (author of the library Faviconic was forked from: https://github.com/ZakMiller/fetch-favicon)
