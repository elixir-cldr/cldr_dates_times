# Changelog for Cldr_Dates_Times v1.2.1

This is the changelog for Cldr_Dates_Times v1.2.1 released on April 1st, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_dates_times/tags)

## Bug Fixes

* Compiles the date_time formats configured under `config :ex_cldr, precompile_datetime_formats: ["..". ".."]` as advertised.  Previously this documented configuration key was being ignored

## Enhancements

* Update `ex_cldr` dependency to version 1.5.1 and `ex_cldr_numbers` version 1.4.1 in order to use `Cldr.Config.app_name()`

# Changelog for Cldr_Dates_Times v1.2.0

### Enhancements

* Update ex_cldr dependency to version 1.5.0 which uses CLDR data version 33.

* Update ex_cldr_numbers dependency to 1.4.0

# Changelog for Cldr_Dates_Times v1.0.1

### Bug Fixes

* Fix @doc heredocs to ensure there is no outdenting which produces a warning on Elixir 1.7
