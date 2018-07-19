# Changelog for Cldr_Dates_Times v1.3.1

This is the changelog for Cldr_Dates_Times v1.3.1 released on July 20th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_dates_times/tags)

## Enhancements

* Update dependencies and remove generated `src/*.erl` files from the package for compatibility with Elixir 1.7

# Changelog for Cldr_Dates_Times v1.3.0

This is the changelog for Cldr_Dates_Times v1.3.0 released on April 18th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_dates_times/tags)

## Enhancements

* Relaxes reqirements for `ex_cldr` and `ex_cldr_numbers`

# Changelog for Cldr_Dates_Times v1.2.2

This is the changelog for Cldr_Dates_Times v1.2.2 released on April 18th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_dates_times/tags)

## Bug Fixes

* Fix date time format lookup for atom formats.  Fixes #3. Thanks to @lostkobrakai

# Changelog for Cldr_Dates_Times v1.2.1

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
