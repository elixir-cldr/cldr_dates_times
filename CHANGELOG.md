# Changelog for Cldr_Dates_Times v2.0

This is the changelog for Cldr_Dates_Times v2.0 released on June 9th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_dates_times/tags)

This release depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which provides the underlying calendar calculations as well as providing a set of additional calendars.

## Breaking Changes

* `ex_cldr_dates_times` requires a minimum Elixir version of 1.8.  It depends on `Calendar` capabilities built into this and later release.

* `ex_cldr_dates_times` now depends upon [ex_cldr version 2.0](https://hex.pm/packages/ex_cldr/2.0.0).  As a result it is a requirement that at least one backend module be configured as described in the [ex_cldr readme](https://hexdocs.pm/ex_cldr/2.0.0/readme.html#configuration).

* The public API is now based upon functions defined on a backend module. Therefore calls to functions such as `Cldr.DateTime.to_string/3` should be replaced with calls to `MyApp.Cldr.DateTime.to_string/3` (assuming your configured backend module is called `MyApp.Cldr`).

## Enhancements

* Correctly calculates `week_of_year`

* Supports `Calendar.ISO` and any calendar defined with `Cldr.Calendar` (see [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars))

## Known limitations

* Does not calculate `week_of_month`. If called will return `1` for all input values.

## Migration

`ex_cldr_dates_times` uses the configuration set for the dependency `ex_cldr`.  See the documentation for [ex_cldr](https://hexdocs.pm/ex_cldr)

Unlike `ex_cldr_dates_times` version 1, version 2 requires one or more `backend` modules to host the functions that manage CLDR data.  An example to get started is:

1. Create a backend module:

```elixir
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "ja"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]

end
```

2. Update `config.exs` configuration to specify this backend as the system default:

```elixir
config :ex_cldr,
  default_locale: "en",
  default_backend: MyApp.Cldr
```

3. Replace calls to `Date`. `Time` and `DateTime` functions `to_string/2` with calls to `to_string/3` where the second parameter is a backend module.