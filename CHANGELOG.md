# Changelog for Cldr_Dates_Times v2.1.1

This is the changelog for Cldr_Dates_Times v2.1.1 released on June 17th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Breaking change

* Support Elixir 1.8 and later only since this package depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which required Elixir 1.8.

# Changelog for Cldr_Dates_Times v2.1.0

This is the changelog for Cldr_Dates_Times v2.1.0 released on June 16th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Enhancements

* All calling `Date`, `Time` and `DateTime` `to_string/3` as `to_string/1` omitting the backend and providing options.  The backend will default to `Cldr.default_backend()`. An exception will be raised if there is no default backend.

* Updates to [ex_cldr_calendars 1.0](https://hex.pm/packages/ex_cldr_calendars/1.0.0) which includes `Cldr.Calendar.week_of_month/1`. The result corresponds to the `W` format which is now implemented as well.

# Changelog for Cldr_Dates_Times v2.0.2

This is the changelog for Cldr_Dates_Times v2.0.2 released on June 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Bug Fixes

* Resolve the actual number system before transliterating a date, time or datetime.  Closes #9.  Thanks to @ribanez7 for the report.

# Changelog for Cldr_Dates_Times v2.0.1

This is the changelog for Cldr_Dates_Times v2.0.1 released on June 9th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Bug Fixes

* Fixes a formatter code generation error when a format is a tuple form not a string form.

# Changelog for Cldr_Dates_Times v2.0.0

This is the changelog for Cldr_Dates_Times v2.0 released on June 9th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

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