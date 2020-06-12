# Changelog for Cldr_Dates_Times v2.5.0

This is the changelog for Cldr_Dates_Times v2.5.0 released on ____, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Enhancements

* Add localized interval formatting with `Cldr.Interval.to_string/3` and specific implementations in `Cldr.Date.Interval.to_string/3`, `Cldr.Time.Interval.to_string/3` and `Cldr.DateTime.to_string/3`

* Add `:precompiled_interval_formats` defined in the backend configuration

### Bug Fixes

* Correct doc examples in README.md. Thanks to @tcitworld. Closes #13.

* Fix options processing for `:style` and `:format` for `Cldr.Date.to_string/3`, `Cldr.DateTime.to_string/3` and `Cldr.Time.to_string/3`.  `:format` is preferred although `:style` is honoured.

* Fix transliteration to other number systems

* Retrieve `:precompiled_date_time_formats` from the backend configuration, not the global configuration


# Changelog for Cldr_Dates_Times v2.4.0

This is the changelog for Cldr_Dates_Times v2.4.0 released on May 4th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Enhancements

* Add `Cldr.Time.hour_format_from_locale/1` to return the hour formatted preferred for a locale

* Add `Cldr.DateTime.Formatter.hour/{2, 4}` that formats the hour part of a time in accordance with locale preferences (including honouring the `hc` key of the `u` language tag extension)

* Add format symbol `ddd` to return the day of the month with ordinal formatting. This not a CLDR standard format symbol.

* Add protocol support for `Cldr.Chars` which is used by `Cldr.to_string/1`

# Changelog for Cldr_Dates_Times v2.3.0

This is the changelog for Cldr_Dates_Times v2.3.0 released on February 2nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Enhancements

* Adds backend modules `MyApp.Cldr.Date`, `MyApp.Cldr.Time` and `MyApp.Cldr.DateTime` that contain the functions `to_string/2` and `to_string!/2`. This means all the `ex_cldr` family of libraries should now be primarily called on the backend modules. This makes aliasing easier too. For example:

```
defmodule MyApp.Cldr do
  use Cldr, providers: [Cldr.Number, Cldr.DateTime], default_locale: "en"
end

defmodule MyApp do
  alias MyApp.Cldr

  def some_fun do
    Cldr.Date.to_string Date.utc_today()
  end
end
```

# Changelog for Cldr_Dates_Times v2.2.4

This is the changelog for Cldr_Dates_Times v2.2.4 released on January 14th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Update tests for Elixir 1.10 date/time inspection changes

* Fix dialyzer warning in generated backend

# Changelog for Cldr_Dates_Times v2.2.3

This is the changelog for Cldr_Dates_Times v2.2.3 released on September 14th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Correctly uses a provided `:backend` option when validating the `:locale` option to the various `to_string/3` calls.  Thanks to @lostkobrakai. Closes #108 and #109.

# Changelog for Cldr_Dates_Times v2.2.2

This is the changelog for Cldr_Dates_Times v2.2.2 released on August 31st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Changes & Deprecations

* Deprecates the option `:format` on `Cldr.DateTime.Relative.to_string/3` in favour of `:style`. `:format` will be removed with `ex_cldr_dates_times` version 3.0

### Bug Fixes

* Return an error tuple immediately when a format code is used but no data is available to fulfill it

# Changelog for Cldr_Dates_Times v2.2.1

This is the changelog for Cldr_Dates_Times v2.2.1 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Fix `@spec` for `Cldr.Date.to_string/3`, `Cldr.Time.to_string/3` and `Cldr.DateTime.to_string/3` as well as the `!` variants.

# Changelog for Cldr_Dates_Times v2.2.0

This is the changelog for Cldr_Dates_Times v2.2.0 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Breaking change

* Support Elixir 1.8 and later only since this package depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which requires Elixir 1.8.

## Bug Fixes

* Fix references to `Cldr.get_current_locale/0` to the current `Cldr/get_locale/0`

* Fix dialyzer warnings

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