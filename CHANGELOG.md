# Changelog

**Note that `ex_cldr_dates_times` version 2.18.0 and later are supported on Elixir 1.12 and later only.**

## Cldr_Dates_Times v2.21.0

This is the changelog for Cldr_Dates_Times v2.21.0 released on January 31st, 2025.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Allow configuration of `ex_cldr_calendars` version 2.0 and later.

## Cldr_Dates_Times v2.20.3

This is the changelog for Cldr_Dates_Times v2.20.3 released on August 17th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix specs to pass with a broader range of dialyzer options.

## Cldr_Dates_Times v2.20.2

This is the changelog for Cldr_Dates_Times v2.20.2 released on August 3rd, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Return a better error when passing options that are not a keyword list to `Cldr.Date.to_string/2`, `Cldr.Time.to_string/2` and `Cldr.DateTime.to_string/2`.

## Cldr_Dates_Times v2.20.1

This is the changelog for Cldr_Dates_Times v2.20.1 released on July 27th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Supports formatting `t:Cldr.Calendar.Duration.t/0` and, on Elixir 1.17 or later, `t:Duration.t/0` structs. For these structs, and only these structs, the `:hour` can be any number. In other cases the number is required to be in the range `0..24`.

## Cldr_Dates_Times v2.20.0

This is the changelog for Cldr_Dates_Times v2.20.0 released on July 26th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix `Cldr.Time.available_formats/3` when the locale parameter is a binary.

### Enhancements

* Modify the `:prefer` option of `to_string/2` to take a list of preferences. Time formats may sometimes have a `:unicode` or `:ascii` preference. Date and datetime formats may have a `:default` or `:variant` preference. The `:prefer` option can now be specified with one or both of these options.

## Cldr_Dates_Times v2.19.2

This is the changelog for Cldr_Dates_Times v2.19.2 released on July 9th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Reinstate `Cldr.DateTime.Format.date_formats/3` which was incorrectly removed in version 2.19. Version 2.19 made efforts to improve the symmetry of `Cldr.Date`, `Cldr.Time` and `Cldr.DateTime`. Part of that work is to have each of those modules contain the functions `formats/3` and `available_formats/3`. It was not intended at this time that the equivalent functions be removed from `Cldr.DateTime.Format`. Thanks to @tjchambers for the report. Closes #51.

## Cldr_Dates_Times v2.19.1

This is the changelog for Cldr_Dates_Times v2.19.1 released on July 8th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Include `:skeleton_tokenizer.xrl` to the hex package definition.

## Cldr_Dates_Times v2.19.0

This is the changelog for Cldr_Dates_Times v2.19.0 released on July 8th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix `Cldr.Date.to_string/2` with the option `era: :variant` to correctly render the variant "AD"/"CE"/"BC"/"BCE" text.

* Fix `Cldr.Date.to_string/2` with the option `period: :variant` to correctly render the variant "am"/"pm" text.

### Enhancements

* Adds support for partial dates in `Cldr.Date.to_string/2`. Partial dates are maps with one or more of the fields `:year`, `:month`, `:day` and `:calendar`.

* Adds support for partial time in `Cldr.Time.to_string/2`. Partial times are maps with one or more of the fields `:hour`, `:minute`, and `:second`.

* Adds support for partial datetimes in `Cldr.DateTime.to_string/2`. Partial datetimes are maps with one or more of the fields `:year`, `:month`, `:day`, `:hour`, `:minute`, `:second` and `:calendar`.

* Adds support for deriving the "best match" format for a date, time or datetime based upon the users requested format or deriving from the available date, time or datetime fields.

* Adds support for formatting using format IDs (atoms that are keys to locale-independent formats) in `Cldr.Date.to_string/2` and `Cldr.Time.to_string/2`. They have been previously supported in `Cldr.DateTime.to_string/2` only.

* Add `MyApp.Cldr.DateTime.Format.common_date_time_format_names/0`.

* Improve the error message if `:hour` is outside the valid range.

## Cldr_Dates_Times v2.18.1

This is the changelog for Cldr_Dates_Times v2.18.1 released on July 1st, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix formatting `am/pm` with format `:narrow` or `:wide`. Thanks to @sysashi for the report. Closes #48.

## Cldr_Dates_Times v2.18.0

This is the changelog for Cldr_Dates_Times v2.18.0 released on May 29th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Clarify format compiler documentation. Thanks to @tjchambers for the issue. Closes #46.

* Fix typos. Thanks to @tjchambers for the PR. Closes #47.

## Cldr_Dates_Times v2.17.1

This is the changelog for Cldr_Dates_Times v2.17.1 released on May 2nd, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Add `config/prod.exs` so that the library can be compiled with `MIX_ENV=prod`. Thanks to @camelpunch for the PR. Closes #45.

## Cldr_Dates_Times v2.17.0

This is the changelog for Cldr_Dates_Times v2.17.0 released on April 21st, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix formatting with formats that have may have pluralization like the `:MMMMW` and `:yw` formats.

* Fix `:underspecs` for dialyzer.

### Enhancements

* Update to [CLDR 45.0](https://cldr.unicode.org/index/downloads/cldr-45) data.

* Adds support for formats that have both unicode whitespace and ascii whitespace versions. The option `:prefer` is added to `Cldr.DateTime.to_string/3`. The default is `prefer: :unicode`. The option `prefer: :ascii` is included for backwards compatibility of older applications. The formats that provide both `:unicode` and `:ascii` versions can be seen from the results of `Cldr.DateTime.Format.date_time_available_formats/2`.

## Cldr_Dates_Times v2.16.0

This is the changelog for Cldr_Dates_Times v2.16.0 released on November 2nd, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix formatting time intervals when the `to` time is not greater than the `from` time. This allows time intervals that cross midnight to be formatted correctly. Thanks to @larshei  for the report. Closes #42.

* Fix compiler warnings on Elixir 1.16.

### Enhancements

* Adds options `:date_format` and `:time_format` to `Cldr.DateTime.Interval.to_string/2` and `Cldr.DateTime.to_string/2`. These options allow separate formatting of the date and time parts of a datetime, including those that are part of an interval. Thanks to @jmoldrich for the report (and patience). Closes #33.

## Cldr_Dates_Times v2.15.0

This is the changelog for Cldr_Dates_Times v2.15.0 released on October 17th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Deprecations

* The support of `:style` as a synonym for `:format` with the functions `Cldr.Time.to_string/2`, `Cldr.Date.to_string/2` and `Cldr.DateTime.to_string/2` is now removed.  The `:style` option is now used to influence the use of "at" formats in `Cldr.DateTime.to_string/2`. `:style` also remains a valid option for interval formatting.

### Enhancements

* Add support for "at" style formatting for `DateTime` structs. This style is documented in [TR35](https://unicode.org/reports/tr35/tr35-dates.html#Date_Time_Combination_Examples) and was introduced in [CLDR 43](https://cldr.unicode.org/index/downloads/cldr-43). Thanks to @jueberschlag for the report and motivation to get this done.

## Cldr_Dates_Times v2.14.3

This is the changelog for Cldr_Dates_Times v2.14.3 released on October 10th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix formatting date intervals with `:month_and_day` style when the last date is in a different year to the first. Thanks to @matt-glover for the report. Closes #40.

## Cldr_Dates_Times v2.14.2

This is the changelog for Cldr_Dates_Times v2.14.2 released on September 24th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix additional typespecs for various functions that allow a string-based locale identifier. Thanks to @jarrodmoldrich for the report.

## Cldr_Dates_Times v2.14.1

This is the changelog for Cldr_Dates_Times v2.14.1 released on September 23rd, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix typespecs for various functions that allow a string-based locale identifier. Thanks to @jarrodmoldrich for the report. Closes #39.

## Cldr_Dates_Times v2.14.0

This is the changelog for Cldr_Dates_Times v2.14.0 released on August 17th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Updates to [ex_cldr version 2.37.0](https://hex.pm/packages/ex_cldr/2.37.0) which includes data from [CLDR release 43](https://cldr.unicode.org/index/downloads/cldr-43)

* Adds an option `:wrapper` to `Cldr.DateTime.to_string/2`, `Cldr.Date.to_string/2` and `Cldr.Time.to_string/2`. The argument is a 2-arity function that receives the parameters `string` and `tag` where `tag` is an atom denoting the time unit being formatted (for example, `:minute` or `:year` or `:literal`). The function must return either iodata or a "safe string" such as that returned by `Phoenix.HTML.Tag.content_tag/3`. The function can be used to wrap format elements in HTML or other tags.

## Cldr_Dates_Times v2.13.3

This is the changelog for Cldr_Dates_Times v2.13.3 released on March 13th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

**This release requires (and configures) `ex_cldr` version 2.36.0 or later. That version fixes the interval format data so that formats required by locales that use 24-hour times are not overwritten by data for 12-hour formats.  As a result, formatting intervals using a format key directly (ie one of the keys in the map returned by `MyApp.Cldr.DateTime.Format.date_time_interval_formats/1`) may find the key has changed.**

* Fixes localised time interval formatting to respect the locale's preference for 12-hour or 24-hour times.  Thanks to @Gladear for the report and collaboration. Closes #35.

## Cldr_Dates_Times v2.13.2

This is the changelog for Cldr_Dates_Times v2.13.2 released on March 12th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fixed interval formats when the format provided is a string (rather than the normal atom-based predefined formats)

* Fixed setting the number system from options (typographical error)

* Removed spurious `IO.inspect/2` output when the format is a string.

## Cldr_Dates_Times v2.13.1

This is the changelog for Cldr_Dates_Times v2.13.1 released on November 12th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fixes doc generation errors (no functional changes to executing code).  Closes #34. THanks to @sax for the report and the PR.

## Cldr_Dates_Times v2.13.0

This is the changelog for Cldr_Dates_Times v2.13.0 released on October 19th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Updates to [CLDR 42](https://cldr.unicode.org/index/downloads/cldr-42).  The data time formats for several locales have changed from "<date> at <time>" to "<date>, <time>". This is a new category of formats that retain the `at` formats but these are not yet exposed in `ex_cldr_dates_times`.

## Cldr_Dates_Times v2.12.0

This is the changelog for Cldr_Dates_Times v2.12.0 released on May 7th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Makes `Cldr.Date.Interval.greatest_difference/2` to be part of the public API. Also adds `Cldr.DateTime.Interval.greatest_difference/2` and `Cldr.Time.Interval.greatest_difference/2`.

## Cldr_Dates_Times v2.11.0

This is the changelog for Cldr_Dates_Times v2.11.0 released on February 21st, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Updates to [ex_cldr version 2.26.0](https://hex.pm/packages/ex_cldr/2.26.0) and [ex_cldr_numbers version 2.25.0](https://hex.pm/packages/ex_cldr_numbers/2.25.0) which use atoms for locale names and rbnf locale names. This is consistent with other elements of `t:Cldr.LanguageTag` where atoms are used when the cardinality of the data is fixed and relatively small and strings where the data is free format.

## Cldr_Dates_Times v2.10.2

This is the changelog for Cldr_Dates_Times v2.10.2 released on January 15th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix `Date.to_string/2` when the second argument is a list of options and not a backend module. Previously this would ignore any `:backend` option and try to use `Cldr.default_backend!/0` which would fail if not one was configured. The same fix is applied to `Cldr.Time.to_string/2` and `Cldr.DateTime.to_string/2`.

## Cldr_Dates_Times v2.10.1

This is the changelog for Cldr_Dates_Times v2.10.1 released on December 1st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Replace `use Mix.Config` with `import Config` in config files

* Correctly call `transliterate_digits/3` not `transliterate/3` when transliterating digits for date/time formats

## Cldr_Dates_Times v2.10.0

This is the changelog for Cldr_Dates_Times v2.10.0 released on October 27th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Improved localization in support of Chinese, Japanese and Korea calendars (era, month names, cyclic year, related gregorian year)

* Updates to support [CLDR release 40](https://cldr.unicode.org/index/downloads/cldr-40) via [ex_cldr version 2.24](https://hex.pm/packages/ex_cldr/2.24.0)

### Bug Fixes

* Fix year formatting to account for different calendar resolvers

### Deprecations

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_config/2` instead.

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

## Cldr_Dates_Times v2.10.0-rc.3

This is the changelog for Cldr_Dates_Times v2.10.0-rc.3 released on October 25th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Deprecations

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

## Cldr_Dates_Times v2.10.0-rc.2

This is the changelog for Cldr_Dates_Times v2.10.0-rc.2 released on October 25th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Deprecations

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_config/2` instead.

## Cldr_Dates_Times v2.10.0-rc.1

This is the changelog for Cldr_Dates_Times v2.10.0-rc.1 released on October 21st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix year formatting to account for different calendar resolvers

## Cldr_Dates_Times v2.10.0-rc.0

This is the changelog for Cldr_Dates_Times v2.10.0-rc.0 released on October 20th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Improved localization in support of Chinese, Japanese and Korea calendars (era, month names, cyclic year, related gregorian year)

* Update to `ex_cldr` version `2.24` which uses [CLDR 40](https://cldr.unicode.org/index/downloads/cldr-40) data

## Cldr_Dates_Times v2.9.4

This is the changelog for Cldr_Dates_Times v2.9.4 released on September 22nd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* Fixes relative date and date time formatting when a `:relative_to` parameter and no `:unit` parameter is specified. Thanks to @maennchen for the report.  Closes #26.

## Cldr_Dates_Times v2.9.3

This is the changelog for Cldr_Dates_Times v2.9.3 released on September 20th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* Fixes relative date and date time formatting when a `:relative_to` parameter and a `:unit` parameter is specified. Thanks to @DaTrader for the report.  Closes #25.

## Cldr_Dates_Times v2.9.2

This is the changelog for Cldr_Dates_Times v2.9.2 released on August 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* Open interval formats can now also be called directly on the backend. For example:

        iex> MyApp.Cldr.Date.Interval.to_string ~D[2020-01-01], nil
        {:ok, "Jan 1, 2020 –"}

## Cldr_Dates_Times v2.9.1

This is the changelog for Cldr_Dates_Times v2.9.1 released on August 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* When formatting an open interval (one side is `nil`) the backend function `date_time_interval_fallback/2` is used to retrieve the format pattern. Previously this function was being called with default parameters. Now it is properly called with a locale and a calendar.

## Cldr_Dates_Times v2.9.0

This is the changelog for Cldr_Dates_Times v2.9.0 released on August 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* Fix splitting interval formats when there is no repeating field. Use the principal that standalone formats are equivalent to normal formats when splitting.  ie, for this purposes "L" == "M". This means the locale "fa" no longer raises an exception.

### Enhancements

* Allow formatting of intervals where one side is `nil`. This will produce an open-ended interval. Only one side of the interval can be `nil`. Thanks to @woylie for the request.  Closes #23.

#### Examples

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], nil, MyApp.Cldr,
      ...> format: :short
      {:ok, "1/1/20 –"}

      iex> Cldr.Time.Interval.to_string ~U[2020-01-01 00:00:00.0Z], nil, MyApp.Cldr,
      ...> format: :long, style: :flex
      {:ok, "12:00:00 AM UTC –"}

      iex> Cldr.DateTime.Interval.to_string ~U[2020-01-01 00:00:00.0Z], nil, MyApp.Cldr
      {:ok, "Jan 1, 2020, 12:00:00 AM –"}

## Cldr_Dates_Times v2.8.0

This is the changelog for Cldr_Dates_Times v2.8.0 released on July 1st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug fixes

* Fixes formatting time intervals that by checking for a format key of `:h` in addition to the `:a` and `:b` format keys (similar to issue #22).

### Enhancements

* Updated to [ex_cldr version 2.23.0](https://hex.pm/packages/ex_cldr/2.23.0) which changes the names of some of the field in the "-u-" extension to match the CLDR canonical name. In particular the field name `hour_cycle` changes to `hc`. The values for `hc` also change to the canonical forms of `:h12`, `:h11`, `:h23` and `:h24`.

## Cldr_Dates_Times v2.7.2

This is the changelog for Cldr_Dates_Times v2.7.2 released on May 6th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix regression time intervals where the start time is "a.m." and the end time is "p.m." and the format code is `:b` (previously assumed `:a`). Thanks to @bryanlep for the report. Closes #22.

## Cldr_Dates_Times v2.7.1

This is the changelog for Cldr_Dates_Times v2.7.1 released on May 6th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix formatting time intervals where the start time is "a.m." and the end time is "p.m.". Thanks to @sfusato for the report. Closes #21.

## Cldr_Dates_Times v2.7.0

This is the changelog for Cldr_Dates_Times v2.7.0 released on April 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Data changes

* Some date and time formats have changed for some locales. This applies to interval date, time and datetime formats in `en` locale for example. Some time formats have also now changed in `en` from 24-hour times to `am/pm` formats.

### Enhancements

* Add support for [CLDR 39](http://cldr.unicode.org/index/downloads/cldr-39)

## Cldr_Dates_Times v2.7.0-rc.0

This is the changelog for Cldr_Dates_Times v2.7.0-rc.0 released on March 19th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Data changes

* Some date and time formats have changed for some locales. This applies to interval date, time and datetime formats in `en` locale for example. Some time formats have also now changed in `en` from 24-hour times to `am/pm` formats.

### Enhancements

* Add support for [CLDR 39](http://cldr.unicode.org/index/downloads/cldr-39)

## Cldr_Dates_Times v2.6.4

This is the changelog for Cldr_Dates_Times v2.6.4 released on December 17th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Remove `xref` section from the project in `mix.exs`. The fixes an error where the configuration for `xref` was incorrect and causing compiler errors on some versions of Elixir. Closes #19. Thanks to @fertapric.

* Make dependencies `eprof` and `dialyixir` optional so that they aren't dragged into host apps unnecessarily.

## Cldr_Dates_Times v2.6.3

This is the changelog for Cldr_Dates_Times v2.6.3 released on December 3rd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* [UPDATED] Fix regression whereby formatting a Date or Time via a backend with no options would raise a `Cldr.NoDefaultBackendError (No default :ex_cldr backend is configured)` exception. Closes #18 properly. Thanks to @maennchen.

## Cldr_Dates_Times v2.6.2

This is the changelog for Cldr_Dates_Times v2.6.2 released on December 2nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Bug Fixes

* Fix regression whereby formatting a DateTime via a backend with no options would raise a `Cldr.NoDefaultBackendError (No default :ex_cldr backend is configured)` exception. Closes #18. Thanks to @maennchen.

## Cldr_Dates_Times v2.6.1

This is the changelog for Cldr_Dates_Times v2.6.1 released on November 30th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Performance improvements

* Don't transliterate when the number system is `:latn` (which it most commonly is). The improves formatting performance by about 40%.

* Handle default parameters more efficiently which improves performance by a further 10%.

## Cldr_Dates_Times v2.6.0

This is the changelog for Cldr_Dates_Times v2.6.0 released on November 1st, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_cldr_dates_times/tags)

### Enhancements

* Add support for [CLDR 38](http://cldr.unicode.org/index/downloads/cldr-38)

## Cldr_Dates_Times v2.5.4

This is the changelog for Cldr_Dates_Times v2.5.4 released on September 26th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Use `Cldr.Date.default_backend/0` as a shim to provide compatibility for the upcoming `ex_cldr` version `2.18.0` where `Cldr.default_backend/0` is deprecated in favour of `Cldr.default_backend!/0`

## Cldr_Dates_Times v2.5.3

This is the changelog for Cldr_Dates_Times v2.5.3 released on September 22nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Fix compiler warns on duplicate `@doc` on Elixir 1.11

## Cldr_Dates_Times v2.5.2

This is the changelog for Cldr_Dates_Times v2.5.2 released on September 2nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Correct the spec for Cldr.DateTime.Relative.to_string!/3. Thanks to @loskobrakai.

## Cldr_Dates_Times v2.5.1

This is the changelog for Cldr_Dates_Times v2.5.1 released on June 17th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Use locale's number system if no optional number system is provided. Fixes `Cldr.Date`, `Cldr.Time` and `Cldr.DateTime`

* Fix datetime formatting for `CalendarInterval`s that have minute precision. In these cases, `:seconds` and `:microseconds` should be zeroed.

* Fix links to `hex.pm` for `calendar_interval`

## Cldr_Dates_Times v2.5.0

This is the changelog for Cldr_Dates_Times v2.5.0 released on June 13th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Enhancements

* Add localized interval formatting with `Cldr.Interval.to_string/3` and specific implementations in `Cldr.Date.Interval.to_string/3`, `Cldr.Time.Interval.to_string/3` and `Cldr.DateTime.to_string/3`

* Add `<backend>.Interval.to_string/3`, `<backend>.Date.Interval.to_string/3`, `<backend>.Time.Interval.to_string/3`, `<backend>.DateTime.Interval.to_string/3`

* Add `:precompiled_interval_formats` defined in the backend configuration

### Bug Fixes

* Correct doc examples in README.md. Thanks to @tcitworld. Closes #13.

* Fix options processing for `:style` and `:format` for `Cldr.Date.to_string/3`, `Cldr.DateTime.to_string/3` and `Cldr.Time.to_string/3`.  `:format` is preferred although `:style` is honoured.

* Fix transliteration to other number systems

* Retrieve `:precompiled_date_time_formats` from the backend configuration, not the global configuration

## Cldr_Dates_Times v2.4.0

This is the changelog for Cldr_Dates_Times v2.4.0 released on May 4th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Enhancements

* Add `Cldr.Time.hour_format_from_locale/1` to return the hour formatted preferred for a locale

* Add `Cldr.DateTime.Formatter.hour/{2, 4}` that formats the hour part of a time in accordance with locale preferences (including honouring the `hc` key of the `u` language tag extension)

* Add format symbol `ddd` to return the day of the month with ordinal formatting. This not a CLDR standard format symbol.

* Add protocol support for `Cldr.Chars` which is used by `Cldr.to_string/1`

## Cldr_Dates_Times v2.3.0

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

## Cldr_Dates_Times v2.2.4

This is the changelog for Cldr_Dates_Times v2.2.4 released on January 14th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Update tests for Elixir 1.10 date/time inspection changes

* Fix dialyzer warning in generated backend

## Cldr_Dates_Times v2.2.3

This is the changelog for Cldr_Dates_Times v2.2.3 released on September 14th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Correctly uses a provided `:backend` option when validating the `:locale` option to the various `to_string/3` calls.  Thanks to @lostkobrakai. Closes #108 and #109.

## Cldr_Dates_Times v2.2.2

This is the changelog for Cldr_Dates_Times v2.2.2 released on August 31st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Changes & Deprecations

* Deprecates the option `:format` on `Cldr.DateTime.Relative.to_string/3` in favour of `:style`. `:format` will be removed with `ex_cldr_dates_times` version 3.0

### Bug Fixes

* Return an error tuple immediately when a format code is used but no data is available to fulfill it

## Cldr_Dates_Times v2.2.1

This is the changelog for Cldr_Dates_Times v2.2.1 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

### Bug Fixes

* Fix `@spec` for `Cldr.Date.to_string/3`, `Cldr.Time.to_string/3` and `Cldr.DateTime.to_string/3` as well as the `!` variants.

## Cldr_Dates_Times v2.2.0

This is the changelog for Cldr_Dates_Times v2.2.0 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Breaking change

* Support Elixir 1.8 and later only since this package depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which requires Elixir 1.8.

## Bug Fixes

* Fix references to `Cldr.get_current_locale/0` to the current `Cldr.get_locale/0`

* Fix dialyzer warnings

## Cldr_Dates_Times v2.1.0

This is the changelog for Cldr_Dates_Times v2.1.0 released on June 16th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Enhancements

* All calling `Date`, `Time` and `DateTime` `to_string/3` as `to_string/1` omitting the backend and providing options.  The backend will default to `Cldr.default_backend()`. An exception will be raised if there is no default backend.

* Updates to [ex_cldr_calendars 1.0](https://hex.pm/packages/ex_cldr_calendars/1.0.0) which includes `Cldr.Calendar.week_of_month/1`. The result corresponds to the `W` format which is now implemented as well.

## Cldr_Dates_Times v2.0.2

This is the changelog for Cldr_Dates_Times v2.0.2 released on June 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Bug Fixes

* Resolve the actual number system before transliterating a date, time or datetime.  Closes #9.  Thanks to @ribanez7 for the report.

## Cldr_Dates_Times v2.0.1

This is the changelog for Cldr_Dates_Times v2.0.1 released on June 9th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_dates_times/tags)

## Bug Fixes

* Fixes a formatter code generation error when a format is a tuple form not a string form.

## Cldr_Dates_Times v2.0.0

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