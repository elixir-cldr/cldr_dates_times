defmodule Cldr.DateTime.Formatter do
  @moduledoc """
  Functions that implement the formatting for each specific
  format symbol.

  Each format symbol is an ASCII character in the
  range `a-zA-z`.  Although not all characters are used as
  format symbols, all characters are reserved for that use
  requiring that literals be enclosed in single quote
  characters, for example `'a literal'`.

  Variations of each format are defined by repeating the
  format symbol one or more times.  CLDR typically defines
  an `:abbreviated`, `:wide` and `:narrow` format that is
  reprented by a sequence of 3, 4 or 5 format symbols but
  this can vary depending on the format symbol.

  The [CLDR standard](http://unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)
  defines a wide range of format symbols.  Most - but not
  all - of these symbols are supported in `Cldr`.  The supported
  symbols are described below.

  ## Format Symbol Table

  | Element                | Symbol     | Example         | Cldr Format                        |
  | :--------------------  | :--------  | :-------------- | :--------------------------------- |
  | Era                    | G, GG, GGG | "AD"            | Abbreviated                        |
  |                        | GGGG       | "Anno Domini"   | Wide                               |
  |                        | GGGGG      | "A"             | Narrow                             |
  | Year                   | y          | 7               | Minimum necessary digits           |
  |                        | yy         | "17"            | Least significant 2 digits         |
  |                        | yyy        | "017", "2017"   | Padded to at least 3 digits        |
  |                        | yyyy       | "2017"          | Padded to at least 4 digits        |
  |                        | yyyyy      | "02017"         | Padded to at least 5 digits        |
  | ISOWeek Year           | Y          | 7               | Minimum necessary digits           |
  |                        | YY         | "17"            | Least significant 2 digits         |
  |                        | YYY        | "017", "2017"   | Padded to at least 3 digits        |
  |                        | YYYY       | "2017"          | Padded to at least 4 digits        |
  |                        | YYYYY      | "02017"         | Padded to at least 5 digits        |
  | Related Gregorian Year | r, rr, rr+ | 2017            | Minimum necessary digits           |
  | Cyclic Year            | U, UU, UUU | "甲子"           | Abbreviated                        |
  |                        | UUUU       | "甲子" (for now) | Wide                               |
  |                        | UUUUU      | "甲子" (for now) | Narrow                             |
  | Extended Year          | u+         | 4601            | Minimim necessary digits           |
  | Quarter                | Q          | 2               | Single digit                       |
  |                        | QQ         | "02"            | Two digits                         |
  |                        | QQQ        | "Q2"            | Abbreviated                        |
  |                        | QQQQ       | "2nd quarter"   | Wide                               |
  |                        | QQQQQ      | "2"             | Narrow                             |
  | Standalone Quarter     | q          | 2               | Single digit                       |
  |                        | qq         | "02"            | Two digits                         |
  |                        | qqq        | "Q2"            | Abbreviated                        |
  |                        | qqqq       | "2nd quarter"   | Wide                               |
  |                        | qqqqq      | "2"             | Narrow                             |
  | Month                  | M          | 9               | Single digit                       |
  |                        | MM         | "09"            | Two digits                         |
  |                        | MMM        | "Sep"           | Abbreviated                        |
  |                        | MMMM       | "September"     | Wide                               |
  |                        | MMMMM      | "S"             | Narrow                             |
  | Standalone Month       | L          | 9               | Single digit                       |
  |                        | LL         | "09"            | Two digits                         |
  |                        | LLL        | "Sep"           | Abbreviated                        |
  |                        | LLLL       | "September"     | Wide                               |
  |                        | LLLLL      | "S"             | Narrow                             |
  | Week of Year           | w          | 2, 22           | Single digit                       |
  |                        | ww         | 02, 22          | Two digits, zero padded            |
  | Week of Month          | W          | 2               | Single digit                       |
  | Day of Year            | D          | 3, 33, 333      | Minimum necessary digits           |
  |                        | DD         | 03, 33, 333     | Minimum of 2 digits, zero padded   |
  |                        | DDD        | 003, 033, 333   | Minimum of 3 digits, zero padded   |
  | Day of Month           | d          | 2, 22           | Minimum necessary digits           |
  |                        | dd         | 02, 22          | Two digits, zero padded            |
  | Day of Week            | E, EE, EEE | "Tue"           | Abbreviated                        |
  |                        | EEEE       | "Tuesday"       | Wide                               |
  |                        | EEEEE      | "T"             | Narrow                             |
  |                        | EEEEEE     | "Tu"            | Short                              |
  |                        | e          | 2               | Single digit                       |
  |                        | ee         | "02"            | Two digits                         |
  |                        | eee        | "Tue"           | Abbreviated                        |
  |                        | eeee       | "Tuesday"       | Wide                               |
  |                        | eeeee      | "T"             | Narrow                             |
  |                        | eeeeee     | "Tu"            | Short                              |
  | Standalone Day of Week | c, cc      | 2               | Single digit                       |
  |                        | ccc        | "Tue"           | Abbreviated                        |
  |                        | cccc       | "Tuesday"       | Wide                               |
  |                        | ccccc      | "T"             | Narrow                             |
  |                        | cccccc     | "Tu"            | Short                              |
  | AM or PM               | a, aa, aaa | "am."           | Abbreviated                        |
  |                        | aaaa       | "am."           | Wide                               |
  |                        | aaaaa      | "am"            | Narrow                             |
  | Noon, Mid, AM, PM      | b, bb, bbb | "mid."          | Abbreviated                        |
  |                        | bbbb       | "midnight"      | Wide                               |
  |                        | bbbbb      | "md"            | Narrow                             |
  | Flexible time period   | B, BB, BBB | "at night"      | Abbreviated                        |
  |                        | BBBB       | "at night"      | Wide                               |
  |                        | BBBBB      | "at night"      | Narrow                             |
  | Hour                   | h, K, H, k |                 | See the table below                |
  | Minute                 | m          | 3, 10           | Minimim digits of minutes          |
  |                        | mm         | "03", "12"      | Two digits, zero padded            |
  | Second                 | s          | 3, 48           | Minimim digits of seconds          |
  |                        | ss         | "03", "48"      | Two digits, zero padded            |
  | Fractional Seconds     | S          | 3, 48           | Minimim digits of fractional seconds |
  |                        | SS         | "03", "48"      | Two digits, zero padded            |
  | Millseconds            | A+         | 4000, 63241     | Minimim digits of milliseconds since midnight |
  | Generic non-location TZ | v         | "Etc/UTC"       | `:time_zone` key, unlocalised      |
  |                         | vvvv      | "unk"           | Generic timezone name.  Currently returns only "unk" |
  | Specific non-location TZ | z..zzz   | "UTC"           | `:zone_abbr` key, unlocalised      |
  |                         | zzzz      | "GMT"           | Delegates to `zone_gmt/4`          |
  | Timezone ID             | V         | "unk"           | `:zone_abbr` key, unlocalised      |
  |                         | VV        | "Etc/UTC        | Delegates to `zone_gmt/4`          |
  |                         | VVV       | "Unknown City"  | Exemplar city.  Not supported.     |
  |                         | VVVV      | "GMT"           | Delegates to `zone_gmt/4           |
  | ISO8601 Format          | Z..ZZZ    | "+0100"         | ISO8601 Basic Format with hours and minutes |
  |                         | ZZZZ      | "+01:00"        | Delegates to `zone_gmt/4           |
  |                         | ZZZZZ     | "+01:00:10"     | ISO8601 Extended format with optional seconds |
  | ISO8601 plus Z          | X         | "+01"           | ISO8601 Basic Format with hours and optional minutes or "Z" |
  |                         | XX        | "+0100"         | ISO8601 Basic Format with hours and minutes or "Z"          |
  |                         | XXX       | "+0100"         | ISO8601 Basic Format with hours and minutes, optional seconds or "Z" |
  |                         | XXXX      | "+010059"       | ISO8601 Basic Format with hours and minutes, optional seconds or "Z" |
  |                         | XXXXX     | "+01:00:10"     | ISO8601 Extended Format with hours and minutes, optional seconds or "Z" |
  | ISO8601 minus Z         | x         | "+0100"         | ISO8601 Basic Format with hours and optional minutes |
  |                         | xx        | "-0800"         | ISO8601 Basic Format with hours and minutes          |
  |                         | xxx       | "+01:00"        | ISO8601 Extended Format with hours and minutes       |
  |                         | xxxx      | "+010059"       | ISO8601 Basic Format with hours and minutes, optional seconds     |
  |                         | xxxxx     | "+01:00:10"     | ISO8601 Extended Format with hours and minutes, optional seconds  |
  | GMT Format              | O         | "+0100"         | Short localised GMT format        |
  |                         | OOOO      | "+010059"       | Long localised GMT format         |

  ## Formatting symbols for hour of day

  The hour of day can be formatted differently depending whether
  a 12- or 24-hour day is being represented and depending on the
  way in which midnight and noon are represented.  The following
  table illustrates the differences:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   h	    |  12	  | 1...11	|  12	 |   1...11   |  12   |
  |   K	    |   0	  | 1...11	|   0	 |   1...11   |   0   |
  |   H	    |   0	  | 1...11	|  12	 |  13...23   |   0   |
  |   k	    |  24	  | 1...11	|  12	 |  13...23   |  24   |

  """
  alias Cldr.DateTime.{Format, Compiler, Timezone}
  alias Cldr.LanguageTag
  alias Cldr.Calendar, as: Kalendar
  alias Cldr.Locale
  alias Cldr.Math

  @doc """
  Returns the formatted and localised date, time or datetime
  for a given `Date`, `Time`, `DateTime` or struct with the
  appropriate fields.

  ## Arguments

  * `date` is a `Date`, `Time`, `DateTime` or other struct that
  contains the required date and time fields.

  * `format` is a valid format string, for example `yy/MM/dd hh:MM`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a keyword list of options.  The valid options are:

    * `:number_system`.  The resulting formatted and localised date/time
    string will be transliterated into this number system. Number system
    is anything returned from `Cldr.Number.System.number_systems_for/1`

  *NOTE* This function is called by `Cldr.Date/to_string/2`, `Cldr.Time.to_string/2`
  and `Cldr.DateTime.to_string/2` which is the preferred API.

  ## Examples

      iex> Cldr.DateTime.Formatter.format %{year: 2017, month: 9, day: 3, hour: 10, minute: 23},
      ...> "yy/MM/dd hh:MM", "en"
      {:ok, "17/09/03 10:09"}

  """
  @spec format(Date.t | Time.t | DateTime.t, String.t, LanguageTag.t | Locale.t, Keyword.t) :: String.t
  def format(date, format, locale \\ Cldr.get_current_locale(), options \\ [])

  # Insert generated functions for each locale and format here which
  # means that the lexing is done at compile time not runtime
  # which improves performance quite a bit.
  for format <- Format.format_list() do
    case Compiler.compile(format) do
      {:ok, transforms} ->
        def format(date, unquote(Macro.escape(format)) = f, locale, options) do
          number_system = if is_map(f), do: f[:number_system], else: options[:number_system]
          formatted = unquote(transforms)

          if error_list = format_errors(formatted) do
            {:error, Enum.join(error_list, "; ")}
          else
            formatted =
              formatted
              |> Enum.join
              |> transliterate(locale, number_system)

            {:ok, formatted}
          end
        end

      {:error, message} ->
        raise Cldr.FormatCompileError, "#{message} compiling date format: #{inspect format}"
    end
  end

  # This is the format function that is executed if the supplied format
  # has not otherwise been precompiled in the code above.  Since this function
  # has to tokenize, compile and then interpret the format string
  # there is a performance penalty.
  def format(date, format, locale, options) do
    case Compiler.tokenize(format) do
      {:ok, tokens, _} ->
        number_system = if is_map(format), do: format[:number_system], else: options[:number_system]
        formatted = apply_transforms(tokens, date, locale, options)

        if error_list = format_errors(formatted) do
          {:error, Enum.join(error_list, "; ")}
        else
          formatted = formatted
          |> Enum.join
          |> transliterate(locale, number_system)

          {:ok, formatted}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Execute the transformation pipeline which does the
  # actual formatting
  defp apply_transforms(tokens, date, locale, options) do
    Enum.map tokens, fn {token, _line, count} ->
      apply(__MODULE__, token, [date, count, locale, options])
    end
  end

  defp transliterate(formatted, _locale, nil) do
    formatted
  end

  defp transliterate(formatted, locale, number_system) do
    Cldr.Number.Transliterate.transliterate(formatted, locale, number_system)
  end

  defp format_errors(list) do
    errors =
      list
      |> Enum.filter(fn {:error, _reason} -> true; _ -> false end)
      |> Enum.map(fn {:error, reason} -> reason end)

    if Enum.empty?(errors), do: nil, else: errors
  end

  @doc """
  Returns the time period for a given time of day.

  ## Arguments

  * `time` is any `Time.t` or a map with at least `:hour`,
    `:minute` and `:second` keys

  * `language` is a binary representation of a valid and
    configured language in `Cldr`

  The time period is a locale-specific key that is used
  to localise a time into a textual representation of "am",
  "pm", "noon", "midnight", "evening", "morning" and so on
  as defined in the CLDR day period rules.

  ## Examples

      iex> Cldr.DateTime.Formatter.time_period_for ~T[06:05:54.515228], "en"
      :morning1

      iex> Cldr.DateTime.Formatter.time_period_for ~T[13:05:54.515228], "en"
      :afternoon1

      iex> Cldr.DateTime.Formatter.time_period_for ~T[21:05:54.515228], "en"
      :night1

      iex> Cldr.DateTime.Formatter.time_period_for ~T[21:05:54.515228], "fr"
      :evening1

  """
  @spec time_period_for(Time.t | Map.t, binary) :: atom
  def time_period_for(time, language)

  @doc """
  Returns a boolean indicating is a given language defines the
  notion of "noon" and "midnight"

  ## Arguments

  * `language` is a binary representation of a valid and
    configured language in `Cldr`

  ## Examples

      iex> Cldr.DateTime.Formatter.language_has_noon_and_midnight? "fr"
      true

      iex> Cldr.DateTime.Formatter.language_has_noon_and_midnight? "en"
      true

      iex> Cldr.DateTime.Formatter.language_has_noon_and_midnight? "af"
      false

  """
  @spec language_has_noon_and_midnight?(binary) :: boolean
  def language_has_noon_and_midnight?(language)

  # Insert generated functions that will identify which time period key
  # is appropriate for a given time value.  Note that we sort the time
  # periods such that the "at" periods come before the "from"/"before"
  # periods so that the functions are defined in the right order.
  for {language, periods} <- Cldr.Config.day_period_info() do
    for {period, times} <- Enum.sort(periods, fn {_k, v}, _p2 -> !!Map.get(v, "at") end) do
      case times do
        %{"at" => [h, m]} ->
          def time_period_for(%{hour: unquote(h), minute: unquote(m)}, unquote(language)) do
            unquote(String.to_atom(period))
          end

        # For when the time range wraps around midnight
        %{"from" => [h1, 0], "before" => [h2, 0]} when h2 < h1 ->
          def time_period_for(%{hour: hour}, unquote(language))
          when rem(hour, 24) >= unquote(h1) or rem(hour, 24) < unquote(h2) do
            unquote(String.to_atom(period))
          end

        # For when the time range does not wrap around midnight
        %{"from" => [h1, 0], "before" => [h2, 0]} ->
          def time_period_for(%{hour: hour}, unquote(language))
          when rem(hour, 24) >= unquote(h1) and rem(hour, 24) < unquote(h2) do
            unquote(String.to_atom(period))
          end
      end
    end

    # We also need a way to find out of a language supports the
    # concept of "noon" and "midnight"
    if Map.get(periods, "noon") && Map.get(periods, "midnight")do
      def language_has_noon_and_midnight?(unquote(language)), do: true
    end
  end

  def language_has_noon_and_midnight?(_), do: false

  #
  # DateTime formatters
  #

  @doc """
  Returns a formatted date.

  DateTime formats are defined in CLDR using substitution rules whereby
  the Date and/or Time are substituted into a format string.  Therefore
  this function crafts a date format string which is then inserted into
  the overall format being requested.
  """
  @spec date(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def date(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def date(%{year: _year, month: _month, day: _day, calendar: _calendar} = d, _n, _locale, options) do
    case Cldr.Date.to_string(d, options) do
      {:ok, date_string} -> date_string
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Returns a formatted time.

  DateTime formats are defined in CLDR using substitution rules whereby
  the Date and/or Time are substituted into a format string.  Therefore
  this function crafts a time format string which is then inserted into
  the overall format being requested.
  """
  @spec time(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def time(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def time(%{hour: _hour, minute: _minute} = t, _n, _locale, options) do
    case Cldr.Time.to_string(t, options) do
      {:ok, time_string} -> time_string
      {:error, _reason} = error -> error
    end
  end

  #
  # Date Formatters
  #

  @doc """
  Returns the `era` (format symbol `G`) of a date
  for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  The only applicable
    option is `:era` with a value of either `nil` (the default) or
    `:variant` which will return the variant form of an era if one
    is available.

  ## Format Symbol

  The representation of the era is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format                 |
  | :--------  | :-------------- | :---------------------------|
  | G, GG, GGG | "AD"            | Abbreviated                 |
  | GGGG       | "Anno Domini    | Wide                        |
  | GGGGG      | "A"             | Narrow                      |

  ## Examples

      iex> Cldr.DateTime.Formatter.era %{year: 2017, month: 12, day: 1, calendar: Calendar.ISO}, 1
      "AD"

      iex> Cldr.DateTime.Formatter.era %{year: 2017, month: 12, day: 1, calendar: Calendar.ISO}, 1,
      ...> "en", era: :variant
      "CE"

      iex> Cldr.DateTime.Formatter.era %{year: 2017, month: 12, day: 1, calendar: Calendar.ISO},
      ...> 4, "fr"
      "après Jésus-Christ"

      iex> Cldr.DateTime.Formatter.era %{year: 2017, month: 12, day: 1, calendar: Calendar.ISO},
      ...> 4, "fr", era: :variant
      "de l’ère commune"

  """
  @spec era(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  @era_variant :era
  def era(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def era(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, n, locale, options) when n in 1..3 do
    get_era(date, :era_abbr, locale, options[@era_variant])
  end

  def era(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 4, locale, options) do
    get_era(date, :era_names, locale, options[@era_variant])
  end

  def era(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 5, locale, options) do
    get_era(date, :era_narrow, locale, options[@era_variant])
  end

  def era(date, _n, _locale, _options) do
    error_return(date, "G", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the `year` (format symbol `y`) of a date
  as an integer. The `y` format returns the year
  as a simple integer in string format.

  The format `yy` is a special case which requests just
  the two low-order digits of the year, zero-padded
  as necessary. For most use cases, `y` or `yy` should
  be adequate.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `year/4`

  ## Format Symbol

  The representation of the quarter is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format                 |
  | :--------  | :-------------- | :---------------------------|
  | y          | 7               | Minimum necessary digits    |
  | yy         | "17"            | Least significant 2 digits  |
  | yyy        | "017", "2017"   | Padded to at least 3 digits |
  | yyyy       | "2017"          | Padded to at least 4 digits |
  | yyyyy      | "02017"         | Padded to at least 5 digits |

  In most cases the length of the `y` field specifies
  the minimum number of   digits to display, zero-padded
  as necessary; more digits will be displayed if needed
  to show the full year.

  ## Examples

      iex> Cldr.DateTime.Formatter.year %{year: 2017, calendar: Calendar.ISO}, 1
      2017

      iex> Cldr.DateTime.Formatter.year %{year: 2017, calendar: Calendar.ISO}, 2
      "17"

      iex> Cldr.DateTime.Formatter.year %{year: 2017, calendar: Calendar.ISO}, 3
      "2017"

      iex> Cldr.DateTime.Formatter.year %{year: 2017, calendar: Calendar.ISO}, 4
      "2017"

      iex> Cldr.DateTime.Formatter.year %{year: 2017, calendar: Calendar.ISO}, 5
      "02017"

  """
  @spec year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def year(%{year: year}, 1, _locale, _options) do
    year
  end

  def year(%{year: year}, 2 = n, _locale, _options) do
    year
    |> rem(100)
    |> pad(n)
  end

  def year(%{year: year}, n, _locale, _options) do
    pad(year, n)
  end

  def year(date, _n, _locale, _options) do
    error_return(date, "y", [:year])
  end

  @doc """
  Returns the `year` (format symbol `Y`) in “Week of Year”
  based calendars in which the year transition occurs
  on a week boundary.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `weeK_aligned_year/4`

  ## Format Symbol

  The representation of the year is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format                 |
  | :--------  | :-------------- | :---------------------------|
  | Y          | 7               | Minimum necessary digits    |
  | YY         | "17"            | Least significant 2 digits  |
  | YYY        | "017", "2017"   | Padded to at least 3 digits |
  | YYYY       | "2017"          | Padded to at least 4 digits |
  | YYYYY      | "02017"         | Padded to at least 5 digits |

  The result may differ from calendar year ‘y’ near
  a year transition. This numeric year designation
  is used in conjunction with pattern character ‘w’
  in the ISO year-week calendar as defined
  by ISO 8601, but can be used in non-Gregorian based
  calendar systems where week date processing is desired.

  The field length is interpreted in the same was as for
  `y`; that is, `yy` specifies use of the two low-order
  year digits, while any other field length specifies a
  minimum number of digits to display.

  ## Examples

      iex(12)> Cldr.DateTime.Formatter.week_aligned_year %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 1
      "2018"

      iex(13)> Cldr.DateTime.Formatter.week_aligned_year %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 2
      "18"

      iex(14)> Cldr.DateTime.Formatter.week_aligned_year %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 3
      "2018"

      iex(15)> Cldr.DateTime.Formatter.week_aligned_year %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 4
      "2018"

      iex(16)> Cldr.DateTime.Formatter.week_aligned_year %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 5
      "02018"

  """
  @spec week_aligned_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def week_aligned_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def week_aligned_year(%{year: _year, month: _month, day: _day, calendar: Calendar.ISO} = date,
                          2 = n, _locale, _options) do
    date
    |> Kalendar.ISOWeek.last_week_of_year
    |> Map.get(:year)
    |> rem(100)
    |> pad(n)
  end

  def week_aligned_year(%{year: _year, month: _month, day: _day, calendar: calendar} = date, 2 =
                        n, _locale, _options) do
    date
    |> calendar.last_week_of_year
    |> Map.get(:year)
    |> rem(100)
    |> pad(n)
  end

  def week_aligned_year(%{year: _year, month: _month, day: _day, calendar: Calendar.ISO} = date,
                        n, _locale, _options) do
    date
    |> Kalendar.ISOWeek.last_week_of_year
    |> Map.get(:year)
    |> pad(n)
  end

  def week_aligned_year(%{year: _year, month: _month, day: _day, calendar: calendar} = date,
                        n, _locale, _options) do
    date
    |> calendar.last_week_of_year
    |> Map.get(:year)
    |> pad(n)
  end

  def week_aligned_year(date, _n, _locale, _options) do
    error_return(date, "Y", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the Extended year (format symbol `u`).

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `weeK_aligned_year/4`

  **NOTE: This current implementation always returns
  the year provided in the supplied date.  This means
  `u` returns the same result as the format `y`.**

  ## Format Symbol

  | Symbol     | Example         | Cldr Format               |
  | :--------  | :-------------- | :------------------------ |
  | u+         | 4601            | Minimim necessary digits  |

  This is a single number designating the year of this
  calendar system, encompassing all supra-year fields.

  For example, for the Julian calendar system, year
  numbers are positive, with an era of BCE or CE. An
  extended year value for the Julian calendar system
  assigns positive values to CE years and negative
  values to BCE years, with 1 BCE being year 0.

  For `u`, all field lengths specify a minimum number of
  digits; there is no special interpretation for `uu`.
  """
  @spec extended_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def extended_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def extended_year(%{year: year, calendar: Calendar.ISO}, n, _locale, _options) do
    pad(year, n)
  end

  def extended_year(%{year: _year, calendar: calendar} = date, n, _locale, _options) do
    date
    |> calendar.extended_year_from_date
    |> pad(n)
  end

  def extended_year(date, _n, _locale, _options) do
    error_return(date, "u", [:year, :calendar])
  end

  @doc """
  Returns the cyclic year (format symbol `U`) name for
  non-gregorian calendars.

  **NOTE: In the current implementation, the cyclic year is
  delegated to `Cldr.DateTime.Formatter.year/3`
  (format symbol `y`) and does not return a localed
  cyclic year.**

  ## Format Symbol

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | U, UU, UUU | "甲子"           | Abbreviated     |
  | UUUU       | "甲子" (for now) | Wide            |
  | UUUUU      | "甲子" (for now) | Narrow          |

  Calendars such as the Chinese lunar
  calendar (and related calendars) and the Hindu calendars
  use 60-year cycles of year names. If the calendar does
  not provide cyclic year name data, or if the year value
  to be formatted is out of the range of years for which
  cyclic name data is provided, then numeric formatting
  is used (behaves like format symbol `y`).

  Currently the CLDR data only provides abbreviated names,
  which will be used for all requested name widths.
  """
  @spec cyclic_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def cyclic_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def cyclic_year(%{year: year}, _n, _locale, _options) do
    year
  end

  def cyclic_year(date, _n, _locale, _options) do
    error_return(date, "U", [:year])
  end

  @doc """
  Returns the related gregorian year (format symbol `r`)
  of a date for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the quarter

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `quarter/4`

  ## Format Symbol

  The representation of the related year is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | r+         | 2017            |                 |

  This corresponds to the extended Gregorian year
  in which the calendar’s year begins. Related
  Gregorian years are often displayed, for example,
  when formatting dates in the Japanese calendar —
  e.g. “2012(平成24)年1月15日” — or in the Chinese
  calendar — e.g. “2012壬辰年腊月初四”. The related
  Gregorian year is usually displayed using the
  ":latn" numbering system, regardless of what
  numbering systems may be used for other parts
  of the formatted date.

  If the calendar’s year is linked to the solar
  year (perhaps using leap months), then for that
  calendar the ‘r’ year will always be at a fixed
  offset from the ‘u’ year.

  For the Gregorian calendar, the ‘r’ year
  is the same as the ‘u’ year. For ‘r’, all field
  lengths specify a minimum number of digits; there
  is no special interpretation for “rr”.
  """
  @spec related_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def related_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def related_year(%{year: year, calendar: Calendar.ISO}, _n, _locale, _options) do
    year
  end

  def related_year(%{} = date, _n, _locale, _options) do
    date
    |> Date.convert!(Calendar.ISO)
    |> Map.get(:year)
  end

  def related_year(date, _n, _locale, _options) do
    error_return(date, "r", [:year, :calendar])
  end

  @doc """
  Returns the `quarter` (format symbol `Q`) of a date
  for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the quarter

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `quarter/4`

  ## Format Symbol

  The representation of the quarter is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | Q          | 2               | Single digit    |
  | QQ         | "02"            | Two digits      |
  | QQQ        | "Q2"            | Abbreviated     |
  | QQQQ       | "2nd quarter"   | Wide            |
  | QQQQQ      | "2"             | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 1
      2

      iex> Cldr.DateTime.Formatter.quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 2
      "02"

      iex> Cldr.DateTime.Formatter.quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 3
      "Q2"

      iex> Cldr.DateTime.Formatter.quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 4
      "2nd quarter"

      iex> Cldr.DateTime.Formatter.quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 5
      "2"

  """
  @spec quarter(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def quarter(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def quarter(%{month: month}, 1, _locale, _options) when month in 1..3,   do: 1
  def quarter(%{month: month}, 1, _locale, _options) when month in 4..6,   do: 2
  def quarter(%{month: month}, 1, _locale, _options) when month in 7..9,   do: 3
  def quarter(%{month: month}, 1, _locale, _options) when month in 10..12, do: 4

  def quarter(%{month: _month} = date, 2, locale, options) do
    quarter(date, 1, locale, options)
    |> pad(2)
  end

  def quarter(%{month: _month, calendar: calendar} = date, 3, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :format, :abbreviated)
  end

  def quarter(%{month: _month, calendar: calendar} = date, 4, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :format, :wide)
  end

  def quarter(%{month: _month, calendar: calendar} = date, 5, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :format, :narrow)
  end

  def quarter(date, _n, _locale, _options) do
    error_return(date, "Q", [:month])
  end

  @doc """
  Returns the standalone `quarter` (format symbol `a`) of a date
  for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the quarter

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `standalone_quarter/4`

  ## Format Symbol

  The representation of the quarter is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | q          | 2               | Single digit    |
  | qq         | "02"            | Two digits      |
  | qqq        | "Q2"            | Abbreviated     |
  | qqqq       | "2nd quarter"   | Wide            |
  | qqqqq      | "2"             | Narrow          |

  ## Examples

      iex(1)> Cldr.DateTime.Formatter.standalone_quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 1
      2

      iex(2)> Cldr.DateTime.Formatter.standalone_quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 2
      "02"

      iex(3)> Cldr.DateTime.Formatter.standalone_quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 3
      "Q2"

      iex(4)> Cldr.DateTime.Formatter.standalone_quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 4
      "2nd quarter"

      iex(5)> Cldr.DateTime.Formatter.standalone_quarter %{month: 4,
      ...> calendar: Calendar.ISO}, 5
      "2"

  """
  @spec standalone_quarter(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def standalone_quarter(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def standalone_quarter(date, 1, locale, options), do: quarter(date, 1, locale, options)
  def standalone_quarter(date, 2, locale, options), do: quarter(date, 2, locale, options)

  def standalone_quarter(%{month: _month, calendar: calendar} = date, 3, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :stand_alone, :abbreviated)
  end

  def standalone_quarter(%{month: _month, calendar: calendar} = date, 4, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :stand_alone, :wide)
  end

  def standalone_quarter(%{month: _month, calendar: calendar} = date, 5, locale, options) do
    quarter(date, 1, locale, options)
    |> get_quarter(locale, calendar, :stand_alone, :narrow)
  end

  def standalone_quarter(date, _n, _locale, _options) do
    error_return(date, "q", [:month])
  end

  @doc """
  Returns the `month` (format symbol `M`) of a date
  for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the month

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `month/4`

  ## Format Symbol

  The representation of the month is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | M          | 9               | Single digit    |
  | MM         | "09"            | Two digits      |
  | MMM        | "Sep"           | Abbreviated     |
  | MMMM       | "September"     | Wide            |
  | MMMMM      | "S"             | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.month %{month: 9, calendar: Calendar.ISO}
      9

      iex> Cldr.DateTime.Formatter.month %{month: 9, calendar: Calendar.ISO}, 2
      "09"

      iex> Cldr.DateTime.Formatter.month %{month: 9, calendar: Calendar.ISO}, 3
      "Sep"

      iex> Cldr.DateTime.Formatter.month %{month: 9, calendar: Calendar.ISO}, 4
      "September"

      iex> Cldr.DateTime.Formatter.month %{month: 9, calendar: Calendar.ISO}, 5
      "S"

  """
  @spec month(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def month(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def month(%{month: month}, 1, _locale, _options) do
    month
  end

  def month(%{month: month}, 2, _locale, _options) do
    pad(month, 2)
  end

  def month(%{month: month, calendar: calendar}, 3, locale, _options) do
    get_month(month, locale, calendar, :format, :abbreviated)
  end

  def month(%{month: month, calendar: calendar}, 4, locale, _options) do
    get_month(month, locale, calendar, :format, :wide)
  end

  def month(%{month: month, calendar: calendar}, 5, locale, _options) do
    get_month(month, locale, calendar, :format, :narrow)
  end

  def month(date, _n, _locale, _options) do
    error_return(date, "M", [:month])
  end

  @doc """
  Returns the `month` (symbol `L`) in standalone format which is
  intended to formatted without an accompanying day (`d`).

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the month

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `standalone_month/4`

  ## Format Symbol

  The representation of the standalone month is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | L          | 9               | Single digit    |
  | LL         | "09"            | Two digits      |
  | LLL        | "Sep"           | Abbreviated     |
  | LLLL       | "September"     | Wide            |
  | LLLLL      | "S"             | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.standalone_month %{month: 9, calendar: Calendar.ISO}
      9

      iex> Cldr.DateTime.Formatter.standalone_month %{month: 9, calendar: Calendar.ISO}, 2
      "09"

      iex> Cldr.DateTime.Formatter.standalone_month %{month: 9, calendar: Calendar.ISO}, 3
      "Sep"

      iex> Cldr.DateTime.Formatter.standalone_month %{month: 9, calendar: Calendar.ISO}, 4
      "September"

      iex> Cldr.DateTime.Formatter.standalone_month %{month: 9, calendar: Calendar.ISO}, 5
      "S"

  """
  @spec standalone_month(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def standalone_month(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def standalone_month(%{month: month}, 1, _locale, _options) do
    month
  end

  def standalone_month(%{month: month}, 2, _locale, _options) do
    pad(month, 2)
  end

  def standalone_month(%{month: month, calendar: calendar}, 3, locale, _options) do
    get_month(month, locale, calendar, :stand_alone, :abbreviated)
  end

  def standalone_month(%{month: month, calendar: calendar}, 4, locale, _options) do
    get_month(month, locale, calendar, :stand_alone, :wide)
  end

  def standalone_month(%{month: month, calendar: calendar}, 5, locale, _options) do
    get_month(month, locale, calendar, :stand_alone, :narrow)
  end

  def standalone_month(date, _n, _locale, _options) do
    error_return(date, "L", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the week of the year (symbol `w`) as an integer.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 2 that determines the format of
    the week of the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `week_of_year/4`

  ## Notes

  Determining the week of the year is influenced
  by two factors:

  1. The calendar in use.  For example the ISO calendar (which
  is the default calendar in Elixir) follows the ISO standard
  in which the first week of the year is the week containing
  the first thursday of the year.

  2. The territory in use.  For example, in the US the first
  week of the year is the week containing January 1st whereas
  many territories follow the ISO standard.

  ## Format Symbol

  The representation of the day of the year is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | w          | 2, 22           |                 |
  | ww         | 02, 22          |                 |

  ## Examples

  """
  @spec week_of_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def week_of_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def week_of_year(%{year: _year, month: _month, day: _day, calendar: Calendar.ISO} = date, n, _locale, _options) do
    date
    |> Kalendar.ISOWeek.week_of_year
    |> pad(n)
  end

  def week_of_year(%{year: _year, month: _month, day: _day, calendar: calendar} = date, n, _locale, _options) do
    date
    |> calendar.week_of_year
    |> pad(n)
  end

  def week_of_year(date, _n, _locale, _options) do
    error_return(date, "w", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the week of the month (format symbol `W`) as an integer.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between that should be between 1 and 4 that
    determines the format of the week of the month

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `week_of_month/4`

  ## Format Symbol

  The representation of the week of the month is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | W          | 2               |                 |

  ## Examples

  """
  @spec week_of_month(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def week_of_month(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def week_of_month(%{year: _year, month: _month, day: _day, calendar: Calendar.ISO} = date, n, _locale, _options) do
    {first_of_month, _fraction} = Kalendar.iso_days_from_date(Kalendar.first_day_of_month(date))
    {days, _fraction} = Kalendar.iso_days_from_date(date)

    (days - first_of_month)
    |> div(7)
    |> pad(n)
  end

  def week_of_month(date, _n, _locale, _options) do
    error_return(date, "W", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the day of the month (symbol `d`) as an integer.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 2 that determines the format of
    the day of month

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `day_of_month/4`

  ## Format Symbol

  The representation of the day of the month is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | d          | 2, 22           |                 |
  | dd         | 02, 22          |                 |

  ## Examples

      iex> Cldr.DateTime.Formatter.day_of_month %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 1
      4

      iex> Cldr.DateTime.Formatter.day_of_month %{year: 2017, month: 1, day: 4,
      ...> calendar: Calendar.ISO}, 2
      "04"

  """
  @spec day_of_month(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def day_of_month(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def day_of_month(%{day: day}, 1, _locale, _options) do
    day
  end

  def day_of_month(%{day: day}, 2, _locale, _options) do
    pad(day, 2)
  end

  def day_of_month(date, _n, _locale, _options) do
    error_return(date, "d", [:day])
  end

  @doc """
  Returns the day of the year (symbol `D`) as an integer in string
  format.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 3 that determines the format of
    the day of year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `day_of_year/4`

  ## Format Symbol

  The representation of the day of the year is made in accordance with
  the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | D          | 3, 33, 333      |                 |
  | DD         | 03, 33, 333     |                 |
  | DDD        | 003, 033, 333   |                 |

  ## Examples

      iex> Cldr.DateTime.Formatter.day_of_year %{year: 2017, month: 1, day: 15,
      ...> calendar: Calendar.ISO}, 1
      "15"

      iex> Cldr.DateTime.Formatter.day_of_year %{year: 2017, month: 1, day: 15,
      ...> calendar: Calendar.ISO}, 2
      "15"

      iex> Cldr.DateTime.Formatter.day_of_year %{year: 2017, month: 1, day: 15,
      ...> calendar: Calendar.ISO}, 3
      "015"

  """
  @spec day_of_year(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def day_of_year(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def day_of_year(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, n, _locale, _options) do
    date
    |> Kalendar.day_of_year
    |> pad(n)
  end

  def day_of_year(date, _n, _locale, _options) do
    error_return(date, "D", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the weekday name (format  symbol `E`) as an string.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 6 that determines the format of
    the day of week

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `day_name/4`

  ## Format Symbol

  The representation of the day name is made in accordance with
  the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | E, EE, EEE | "Tue"           | Abbreviated     |
  | EEEE       | "Tuesday"       | Wide            |
  | EEEEE      | "T"             | Narrow          |
  | EEEEEE     | "Tu"            | Short           |

  ## Examples

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 6
      "Tu"

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 5
      "T"

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 3
      "Tue"

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 2
      "Tue"

      iex> Cldr.DateTime.Formatter.day_name %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 1
      "Tue"

  """
  @spec day_name(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def day_name(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def day_name(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, n, locale, _options) when n in 1..3 do
    get_day(date, locale, :format, :abbreviated)
  end

  def day_name(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 4, locale, _options) do
    get_day(date, locale, :format, :wide)
  end

  def day_name(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 5, locale, _options) do
    get_day(date, locale, :format, :narrow)
  end

  def day_name(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 6, locale, _options) do
    get_day(date, locale, :format, :short)
  end

  def day_name(date, _n, _locale, _options) do
    error_return(date, "E", [:year, :month, :day, :calendar])
  end

  @doc """
  Returns the local day of week (format symbol `e`) as a
  number or name.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 6 that determines the format of
    the day of week

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `day_of_week/4`

  ## Notes

  Returns the same as format symbol `E` except that it adds a
  numeric value that will depend on the local starting day
  of the week.

  ## Format Symbol

  The representation of the time period is made in accordance with
  the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | e          | 2               | Single digit    |
  | ee         | "02"            | Two digits      |
  | eee        | "Tue"           | Abbreviated     |
  | eeee       | "Tuesday"       | Wide            |
  | eeeee      | "T"             | Narrow          |
  | eeeeee     | "Tu"            | Short           |

  ## Examples

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 3
      "Tue"

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 5
      "T"

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 6
      "Tu"

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 1
      "2"

      iex> Cldr.DateTime.Formatter.day_of_week %{year: 2017, month: 8, day: 15,
      ...> calendar: Calendar.ISO}, 2
      "02"

  """
  @spec day_of_week(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def day_of_week(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def day_of_week(%{year: year, month: month, day: day, calendar: calendar}, n, locale, _options)
  when n in 1..2 do
    # Calendar day is based upon Monday == 1
    calendar_day_of_week = calendar.day_of_week(year, month, day)

    # Locale start of week can be Monday == 1 through Sunday == 7
    locale_week_starts_on = Kalendar.first_day_of_week(locale)

    convert_calendar_day_to_locale_day(calendar_day_of_week, locale_week_starts_on)
    |> pad(n)
  end

  def day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, n, locale, options)
  when n >= 3 do
    day_name(date, n, locale, options)
  end

  def day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, _n, _locale, _options) do
    error_return(date, "e", [:year, :month, :day, :calendar])
  end

  defp convert_calendar_day_to_locale_day(calendar_day_of_week, locale_week_starts_on) do
    Math.amod(calendar_day_of_week - locale_week_starts_on + 1, 7)
    |> trunc
  end

  @doc """
  Returns the stand-alone local day (format symbol `c`)
  of week number/name.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:year`, `:month`, `:day` and `:calendar`

  * `n` in an integer between 1 and 6 that determines the format of
    the day of week

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `standalone_day_of_week/4`

  ## Notes

  This is the same as `weekday_number/4` except that it is intended
  for use without the associated `d` format symbol.

  ## Format Symbol

  The representation of the time period is made in accordance with
  the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | c, cc      | 2               | Single digit    |
  | ccc        | "Tue"           | Abbreviated     |
  | cccc       | "Tuesday"       | Wide            |
  | ccccc      | "T"             | Narrow          |
  | cccccc     | "Tu"            | Short           |

  ## Examples

      iex> Cldr.DateTime.Formatter.standalone_day_of_week %{year: 2017, month: 8,
      ...> day: 15, calendar: Calendar.ISO}, 3
      "Tue"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week %{year: 2017, month: 8,
      ...> day: 15, calendar: Calendar.ISO}, 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week %{year: 2017, month: 8,
      ...> day: 15, calendar: Calendar.ISO}, 5
      "T"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week %{year: 2017, month: 8,
      ...> day: 15, calendar: Calendar.ISO}, 6
      "Tu"

  """
  @spec standalone_day_of_week(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def standalone_day_of_week(date, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def standalone_day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, n, locale, _options)
  when n in 1..3 do
    get_day(date, locale, :stand_alone, :abbreviated)
  end

  def standalone_day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 4, locale, _options) do
    get_day(date, locale, :stand_alone, :wide)
  end

  def standalone_day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 5, locale, _options) do
    get_day(date, locale, :stand_alone, :narrow)
  end

  def standalone_day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, 6, locale, _options) do
    get_day(date, locale, :stand_alone, :short)
  end

  def standalone_day_of_week(%{year: _year, month: _month, day: _day, calendar: _calendar} = date, _n, _locale, _options) do
    error_return(date, "c", [:year, :month, :day, :calendar])
  end

  #
  # Time formatters
  #

  @doc """
  Returns a localised version of `am` or `pm` (format symbol `a`).

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the
    key `:second`

  * `n` in an integer between 1 and 5 that determines the format of the
    time period

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  The available option is
    `period: :variant` which will use a veriant of localised "am" or
    "pm" if one is available

  ## Notes

  May be upper or lowercase depending on the locale and other options.
  The wide form may be the same as the short form if the “real”
  long form (eg ante meridiem) is not customarily used.

  ## Format Symbol

  The representation of the time period is made in accordance with the following
  table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | a, aa, aaa | "am."           | Abbreviated     |
  | aaaa       | "am."           | Wide            |
  | aaaaa      | "am"            | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 0, minute: 0}
      "AM"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 3, minute: 0}
      "AM"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 13, minute: 0}
      "PM"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 21, minute: 0}
      "PM"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 0, minute: 0}, 1, "en", period: :variant
      "am"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 13, minute: 0}, 1, "en", period: :variant
      "pm"

      iex> Cldr.DateTime.Formatter.period_am_pm %{hour: 13, minute: 0}, 1, "fr", period: :variant
      "PM"

  """
  @spec period_am_pm(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  @period_variant :period
  def period_am_pm(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def period_am_pm(%{hour: _hour} = time, n, locale, options)  do
    calendar = Map.get(time, :calendar, options[:calendar] || Calendar.ISO)
    type = period_type(n)

    key = am_or_pm(time, options)
    get_period(locale, calendar, :format, type, key, options[@period_variant])
  end

  def period_am_pm(time, _n, _locale, _options) do
    error_return(time, "a", [:hour])
  end
  defdelegate period(time, n, locale, options), to: __MODULE__, as: :period_am_pm
  defdelegate period(time, n, locale), to: __MODULE__, as: :period_am_pm
  defdelegate period(time, n), to: __MODULE__, as: :period_am_pm
  defdelegate period(time), to: __MODULE__, as: :period_am_pm

  @doc """
  Returns the formatting of the time period as either
  `noon`, `midnight` or `am`/`pm` (format symbol 'b').

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the
    key `:second`

  * `n` in an integer between 1 and 5 that determines the format of the
    time period

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  The available option is
    `period: :variant` which will use a veriant of localised "noon" and
    "midnight" if one is available

  ## Notes

  If the langauge doesn't support "noon" or "midnight" then
  `am`/`pm` is used for all time periods.

  May be upper or lowercase depending on the locale and other options.
  If the locale doesn't the notion of a unique `noon == 12:00`,
  then the PM form may be substituted. Similarly for `midnight == 00:00`
  and the AM form.

  ## Format Symbol

  The representation of the time period is made in accordance with the following
  table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | b, bb, bbb | "mid."          | Abbreviated     |
  | bbbb       | "midnight"      | Wide            |
  | bbbbb      | "md"            | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 12, minute: 0}
      "noon"

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 0, minute: 0}
      "midnight"

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 11, minute: 0}
      "AM"

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 16, minute: 0}
      "PM"

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 16, minute: 0}, 1, "en",
      ...> period: :variant
      "pm"

  """
  @spec period_noon_midnight(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def period_noon_midnight(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def period_noon_midnight(%{hour: hour, minute: minute} = time, n, locale, options)
  when (rem(hour, 12) == 0 or rem(hour, 24) == 0) and minute == 0 do
    calendar = Map.get(time, :calendar, options[:calendar] || Calendar.ISO)
    type = period_type(n)

    if language_has_noon_and_midnight?(locale.language) do
      time_period = time_period_for(time, locale.language)
      get_period(locale, calendar, :format, type, time_period, options[@period_variant])
    else
      period_am_pm(time, n, locale, options)
    end
  end

  def period_noon_midnight(%{hour: _hour, minute: _minute} = time, n, locale, options) do
    period_am_pm(time, n, locale, options)
  end

  def period_noon_midnight(time, _n, _locale, _options) do
    error_return(time, "b", [:hour, :minute])
  end

  @doc """
  Returns the formatting of the time period as a string, for
  example `at night` (format symbol `B`).

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the
    key `:second`

  * `n` in an integer between 1 and 5 that determines the format of the
    time period

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  The available option is
    `period: :variant` which will use a veriant of localised flexible time
    period names if one is available

  ## Notes

  The time period may be upper or lowercase depending on the locale and
  other options.  Often there is only one width that is customarily used.

  ## Format Symbol

  The representation of the time period is made in accordance with the following
  table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | B, BB, BBB | "at night"      | Abbreviated     |
  | BBBB       | "at night"      | Wide            |
  | BBBBB      | "at night"      | Narrow          |

  ## Examples

      iex> Cldr.DateTime.Formatter.period_flex %{hour: 11, minute: 5, second: 23}
      "in the morning"

      iex> Cldr.DateTime.Formatter.period_flex %{hour: 16, minute: 5, second: 23}
      "in the afternoon"

      iex> Cldr.DateTime.Formatter.period_flex %{hour: 23, minute: 5, second: 23}
      "at night"

  """
  @spec period_flex(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def period_flex(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def period_flex(%{hour: _hour, minute: _minute} = time, n, locale, options) do
    calendar = Map.get(time, :calendar, options[:calendar] || Calendar.ISO)
    time_period = time_period_for(time, locale.language)
    type = period_type(n)

    get_period(locale, calendar, :format, type, time_period, options[@period_variant])
  end

  def period_flex(time, _n, _locale, _options) do
    error_return(time, "B", [:hour, :minute])
  end

  defp period_type(n) when n in 1..3, do: :abbreviated
  defp period_type(4), do: :wide
  defp period_type(5), do: :narrow

  defp am_or_pm(%{hour: hour, minute: _minute}, _variants) when hour < 12 or rem(hour, 24) == 0 do
    :am
  end

  defp am_or_pm(%{}, _variants) do
    :pm
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `h`) as a number in the
  range 1..12 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `hour_1_12/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   h     |  12    | 1...11  |  12  |  1...11   |  12   |

  ## Examples

      iex> Cldr.DateTime.Formatter.hour_1_12 %{hour: 0}
      "12"

      iex> Cldr.DateTime.Formatter.hour_1_12 %{hour: 12}
      "12"

      iex> Cldr.DateTime.Formatter.hour_1_12 %{hour: 24}
      "12"

      iex> Cldr.DateTime.Formatter.hour_1_12 %{hour: 11}
      "11"

      iex> Cldr.DateTime.Formatter.hour_1_12 %{hour: 23}
      "11"

  """
  @spec hour_1_12(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def hour_1_12(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def hour_1_12(%{hour: hour}, n, _locale, _options) when hour in [0, 12, 24] do
    12
    |> pad(n)
  end

  def hour_1_12(%{hour: hour}, n, _locale, _options) when hour in 1..11 do
    hour
    |> pad(n)
  end

  def hour_1_12(%{hour: hour}, n, _locale, _options) when hour in 13..23 do
    (hour - 12)
    |> pad(n)
  end

  def hour_1_12(time, _n, _locale, _options) do
    error_return(time, "h", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `K`) as a number in the
  range 0..11 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `hour_0_11/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   K     |   0   | 1...11  |   0  |  1...11    |   0   |

  ## Examples

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 0}
      "0"

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 12}
      "0"

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 24}
      "0"

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 23}
      "11"

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 11}
      "11"

      iex> Cldr.DateTime.Formatter.hour_0_11 %{hour: 9}
      "9"

  """
  @spec hour_0_11(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def hour_0_11(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def hour_0_11(%{hour: hour}, n, _locale, _options) when hour in [0, 12, 24] do
    0
    |> pad(n)
  end

  def hour_0_11(%{hour: hour}, n, _locale, _options) when hour in 1..11 do
    hour
    |> pad(n)
  end

  def hour_0_11(%{hour: hour}, n, _locale, _options) when hour in 13..23 do
    (hour - 12)
    |> pad(n)
  end

  def hour_0_11(time, _n, _locale, _options) do
    error_return(time, "K", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `k`) as a number in the
  range 1..24 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `hour_1_24/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   k     |  24   | 1...11  |  12  |  13...23   |  24   |

  ## Examples

      iex(4)> Cldr.DateTime.Formatter.hour_1_24 %{hour: 0}
      "24"

      iex(5)> Cldr.DateTime.Formatter.hour_1_24 %{hour: 12}
      "12"

      iex(6)> Cldr.DateTime.Formatter.hour_1_24 %{hour: 13}
      "13"

      iex(7)> Cldr.DateTime.Formatter.hour_1_24 %{hour: 9}
      "9"

      iex(8)> Cldr.DateTime.Formatter.hour_1_24 %{hour: 24}
      "24"

  """
  @spec hour_1_24(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def hour_1_24(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def hour_1_24(%{hour: hour}, n, _locale, _options) when hour in [0, 24] do
    24
    |> pad(n)
  end

  def hour_1_24(%{hour: hour}, n, _locale, _options) when hour in 1..23 do
    hour
    |> pad(n)
  end

  def hour_1_24(time, _n, _locale, _options) do
    error_return(time, "k", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `H`) as a number
  in the range 0..23 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `hour_0_23/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   H     |   0   | 1...11  |  12  |  13...23   |   0   |

  ## Examples:

      iex> Cldr.DateTime.Formatter.hour_0_23 %{hour: 10}
      "10"

      iex> Cldr.DateTime.Formatter.hour_0_23 %{hour: 13}
      "13"

      iex> Cldr.DateTime.Formatter.hour_0_23 %{hour: 21}
      "21"

      iex> Cldr.DateTime.Formatter.hour_0_23 %{hour: 24}
      "0"

      iex> Cldr.DateTime.Formatter.hour_0_23 %{hour: 0}
      "0"

  """
  @spec hour_0_23(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def hour_0_23(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def hour_0_23(%{hour: hour}, n, _locale, _options) when abs(hour) in [0, 24] do
    0
    |> pad(n)
  end

  def hour_0_23(%{hour: hour}, n, _locale, _options) when abs(hour) in 1..23 do
    abs(hour)
    |> pad(n)
  end

  def hour_0_23(time, _n, _locale, _options) do
    error_return(time, "H", [:hour])
  end
  defdelegate hour(time, n, locale, options), to: __MODULE__, as: :hour_0_23
  defdelegate hour(time, n, locale), to: __MODULE__, as: :hour_0_23
  defdelegate hour(time, n), to: __MODULE__, as: :hour_0_23
  defdelegate hour(time), to: __MODULE__, as: :hour_0_23

  @doc """
  Returns the `:minute` of a `time` or `datetime` (format symbol `m`) as number
  in string format.  The number of `m`'s in the format determines the formatting.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:minute`

  * `n` is the number of digits to which `:minute` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `minute/4`

  ## Format Symbol

  The representation of the `minute` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                           |
  | :----  | :--------- | :---------------------------------------------------- |
  | m      | 3, 10      | Minimim digits of minutes                             |
  | mm     | "03", "12" | Number of minutes zero-padded to 2 digits             |

  ## Examples

      iex> Cldr.DateTime.Formatter.minute %{minute: 3}, 1
      3

      iex> Cldr.DateTime.Formatter.minute %{minute: 3}, 2
      "03"

  """
  @spec minute(Map.t, non_neg_integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def minute(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def minute(%{minute: minute}, 1, _locale, _options) do
    minute
  end

  def minute(%{minute: minute}, 2 = n, _locale, _options) do
    minute
    |> pad(n)
  end

  def minute(time, _n, _locale, _options) do
    error_return(time, "m", [:minute])
  end

  @doc """
  Returns the `:second` of a `time` or `datetime` (format symbol `s`) as number
  in string format.  The number of `s`'s in the format determines the formatting.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `second/4`

  ## Format Symbol

  The representation of the `second` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                           |
  | :----  | :--------- | :---------------------------------------------------- |
  | s      | 3, 48      | Minimim digits of seconds                             |
  | ss     | "03", "48" | Number of seconds zero-padded to 2 digits             |

  ## Examples

      iex> Cldr.DateTime.Formatter.second %{second: 23}, 1
      "23"

      iex> Cldr.DateTime.Formatter.second %{second: 4}, 2
      "04"
  """
  @spec second(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def second(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def second(%{second: second}, n, _locale, _options) do
    second
    |> pad(n)
  end

  def second(time, _n, _locale, _options) do
    error_return(time, "s", [:second])
  end

  @doc """
  Returns the `:second` of a `time` or `datetime` (format symbol `S`) as float
  in string format. The seconds are calculate to include microseconds if they
  are available.  The number of `S`'s in the format determines the formatting.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`
    with and optional `:microsecond` key of the format used by `Time`

  * `n` is the number of fractional digits to which the float number of seconds
    is rounded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `fractional_second/4`

  ## Format Symbol

  The representation of the `second` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                           |
  | :----  | :--------- | :---------------------------------------------------- |
  | S      | "4.0"      | Minimim digits of fractional seconds                  |
  | SS     | "4.00"     | Number of seconds zero-padded to 2 fractional digits  |
  | SSS    | "4.002"    | Number of seconds zero-padded to 3 fractional digits  |

  ## Examples

      iex> Cldr.DateTime.Formatter.fractional_second %{second: 4, microsecond: {2000, 3}}, 1
      "4.0"

      iex> Cldr.DateTime.Formatter.fractional_second %{second: 4, microsecond: {2000, 3}}, 3
      "4.002"

      iex> Cldr.DateTime.Formatter.fractional_second %{second: 4}, 1
      "4"

  """
  @spec fractional_second(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def fractional_second(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])

  # Note that TR35 says we should truncate the number of decimal digits
  # but we are rounding
  @microseconds 1_000_000
  def fractional_second(%{second: second, microsecond: {fraction, resolution}}, n, _locale, _options) do
    rounding = min(resolution, n)
    ((second  * 1.0) + fraction / @microseconds)
    |> Float.round(rounding)
    |> to_string
  end

  def fractional_second(%{second: second}, n, _locale, _options) do
    second
    |> pad(n)
  end

  def fractional_second(time, _n, _locale, _options) do
    error_return(time, "S", [:second])
  end

  @doc """
  Returns the `time` (format symbol `A`) as millisenconds since
  midnight.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`
    with and optional `:microsecond` key of the format used by `Time`

  * `n` is the number of fractional digits to which the float number of seconds
    is rounded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `millisecond/4`

  ## Format Symbol

  The representation of the `milliseconds` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                             |
  | :----  | :--------- | :------------------------------------------------------ |
  | A+     | "4000"     | Minimum necessary digits of milliseconds since midnight |

  ## Examples

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 0, minute: 0, second: 4, microsecond: {2000, 3}}, 1
      "4002"

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 0, minute: 0, second: 4}, 1
      "4000"

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 10, minute: 10, second: 4}, 1
      "36604000"

      iex> Cldr.DateTime.Formatter.millisecond ~T[07:35:13.215217]
      "27313215"

  """
  @milliseconds 1_000
  @spec millisecond(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def millisecond(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def millisecond(%{hour: hour, minute: minute, second: second,
                    microsecond: {fraction, _resolution}}, n, _locale, _options) do
    ((rem(hour, 24) * @milliseconds * 60 * 60) +
    (minute * @milliseconds * 60) +
    (second * @milliseconds) +
    div(fraction, @milliseconds))
    |> pad(n)
  end

  def millisecond(%{hour: hour, minute: minute, second: second}, n, _locale, _options) do
    ((rem(hour, 24) * @milliseconds * 60 * 60) +
    (minute * @milliseconds * 60) +
    (second * @milliseconds))
    |> pad(n)
  end

  def millisecond(time, _n, _locale, _options) do
    error_return(time, "A", [:hour, :minute, :second])
  end

  @doc """
  Returns the generic non-location format of a timezone (format symbol `v`)
  from a `DateTime` or `Time`.

  Since Elixir does not provide full time zone support, we return here only
  the `:time_zone` element of the provided `DateTime` or other struct without
  any localization.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:time_zone`
    key of the format used by `Time`

  * `n` is the generic non-location timezone format and is either `1` (the
    default) or `4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `zone_generic/4`

  ## Format Symbol

  The representation of the `timezone` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                             |
  | :----  | :--------- | :------------------------------------------------------ |
  | v      | "Etc/UTC"  | `:time_zone` key, unlocalised                           |
  | vvvv   | "unk"      | Generic timezone name.  Currently returns only "unk"    |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_generic %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 4
      "GMT"

      iex> Cldr.DateTime.Formatter.zone_generic %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 1
      "Etc/UTC"

  """
  @spec zone_generic(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_generic(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_generic(%{time_zone: time_zone, utc_offset: _, std_offset: _}, 1, _locale, _options) do
    time_zone
  end

  def zone_generic(%{time_zone: _time_zone, utc_offset: _, std_offset: _} = time, 4, locale, options) do
    zone_id(time, 4, locale, options)
  end

  def zone_generic(time, _n, _locale, _options) do
    error_return(time, "v", [:time_zone, :utc_offset, :std_offset])
  end

  @doc """
  Returns the specific non-location format of a timezone (format symbol `z`)
  from a `DateTime` or `Time`.

  Since Elixir does not provide full time zone support, we return here only
  the `:time_zone` element of the provided `DateTime` or other struct without
  any localization.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:zone_abbr`,
  `:utc_offset` and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
   `zone_short/4`

  ## Format Symbol

  The representation of the `timezone` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                             |
  | :----  | :--------- | :------------------------------------------------------ |
  | z..zzz | "UTC"      | `:zone_abbr` key, unlocalised                           |
  | zzzz   | "GMT"      | Delegates to `zone_gmt/4`                               |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_short %{zone_abbr: "UTC", utc_offset: 0, std_offset: 0}, 1
      "UTC"

      iex> Cldr.DateTime.Formatter.zone_short %{zone_abbr: "UTC", utc_offset: 0, std_offset: 0}, 4
      "GMT"

  """
  @spec zone_generic(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_short(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_short(%{zone_abbr: zone_abbr}, n, _locale, _options) when n in 1..3 do
    zone_abbr
  end

  def zone_short(%{zone_abbr: _zone_abbr} = time, 4 = n, locale, options) do
    zone_gmt(time, n, locale, options)
  end

  def zone_short(time, _n, _locale, _options) do
    error_return(time, "z", [:zone_abbr])
  end

  @doc """
  Returns the time zone ID (format symbol `V`) part of a `DateTime` or `Time`

  For now the short timezone name, exemplar city and generic location
  formats are not supported and therefore return the fallbacks defined in CLDR.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:utc_offset`
    and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
   `zone_id/4`

  ## Format Symbol

  The representation of the `timezone ID` is made in accordance with the following
  table:

  | Symbol | Results        | Description                                             |
  | :----  | :------------- | :------------------------------------------------------ |
  | V      | "unk"          | `:zone_abbr` key, unlocalised                           |
  | VV     | "Etc/UTC       | Delegates to `zone_gmt/4`                               |
  | VVV    | "Unknown City" | Examplar city.  Not supported.                          |
  | VVVV   | "GMT"          | Delegates to `zone_gmt/4                                |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 1
      "unk"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 2
      "Etc/UTC"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 3
      "Unknown City"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 4
      "GMT"

  """
  @spec zone_id(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_id(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_id(%{time_zone: _time_zone}, 1, _locale, _options) do
    "unk"
  end

  def zone_id(%{time_zone: time_zone}, 2, _locale, _options) do
    time_zone
  end

  def zone_id(%{time_zone: _time_zone}, 3, _locale, _options) do
    "Unknown City"
  end

  def zone_id(%{time_zone: _time_zone} = time, 4, locale, options) do
    zone_gmt(time, 4, locale, options)
  end

  def zone_id(time, _n, _locale, _options) do
    error_return(time, "V", [:time_zone])
  end

  @doc """
  Returns the basic zone offset (format symbol `Z`) part of a `DateTime` or `Time`,

  The ISO8601 basic format with hours, minutes and optional seconds fields.
  The format is equivalent to RFC 822 zone format (when optional seconds field
  is absent). This is equivalent to the "xxxx" specifier.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:utc_offset`
    and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `zone_basic/4`

  ## Format Symbol

  The representation of the `timezone` is made in accordance with the following
  table:

  | Symbol | Results        | Description                                             |
  | :----  | :------------- | :------------------------------------------------------ |
  | Z..ZZZ | "+0100"        | ISO8601 Basic Format with hours and minutes             |
  | ZZZZ   | "+01:00"       | Delegates to `zone_gmt/4                                |
  | ZZZZZ  | "+01:00:10"    | ISO8601 Extended format with optional seconds           |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC", utc_offset: 3600, std_offset: 0}, 1
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 4
      "GMT+01:00"

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 5
      "Z"

      iex(79)> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

  """
  @spec zone_basic(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_basic(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_basic(%{utc_offset: _offset, std_offset: _std_offset} = time, n, _locale, _options) when n in 1..3 do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
  end

  def zone_basic(%{utc_offset: _offset, std_offset: _std_offset} = time, 4 = n, locale, options) do
    zone_gmt(time, n, locale, options)
  end

  def zone_basic(%{utc_offset: _offset, std_offset: _std_offset} = time, 5, _locale, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
  end

  def zone_basic(time, _n, _locale, _options) do
    error_return(time, "Z", [:utc_offset])
  end

  @doc """
  Returns the ISO zone offset (format symbol `X`) part of a `DateTime` or `Time`,

  This is the ISO8601 format with hours, minutes and optional seconds fields with
  "Z" as the identifier if the timezone offset is 0.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:utc_offset`
    and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `zone_iso_z/4`

  ## Format Symbol

  The representation of the `timezone offset` is made in accordance with the following
  table:

  | Symbol | Results        | Description                                                              |
  | :----  | :------------- | :----------------------------------------------------------------------- |
  | X      | "+01"          | ISO8601 Basic Format with hours and optional minutes or "Z"              |
  | XX     | "+0100"        | ISO8601 Basic Format with hours and minutes or "Z"                       |
  | XXX    | "+0100"        | ISO8601 Basic Format with hours and minutes, optional seconds or "Z"     |
  | XXXX   | "+010059"      | ISO8601 Basic Format with hours and minutes, optional seconds or "Z"     |
  | XXXXX  | "+01:00:10"    | ISO8601 Extended Format with hours and minutes, optional seconds or "Z"  |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 1
      "+01"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 2
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 3
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 4
      "+010010"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 5
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 4
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 3
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 2
      "Z"

  """
  @spec zone_iso_z(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_iso_z(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_iso_z(%{utc_offset: _offset, std_offset: _std_offset} = time, 1, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
        |> String.replace(~r/00\Z/, "")
    end
  end

  def zone_iso_z(%{utc_offset: _offset, std_offset: _std_offset} = time, 2, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
    end
  end

  def zone_iso_z(%{utc_offset: _offset, std_offset: _std_offset} = time, 3, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
    end
  end

  def zone_iso_z(%{utc_offset: _offset, std_offset: _std_offset} = time, 4, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"
      {hours, minutes, 0 = seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic) <> pad(seconds, 2)
    end
  end

  def zone_iso_z(%{utc_offset: _offset, std_offset: _std_offset} = time, 5, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
    end
  end

  def zone_iso_z(time, _n, _locale, _options) do
    error_return(time, "X", [:utc_offset])
  end

  @doc """
  Returns the ISO zone offset (format symbol `x`) part of a `DateTime` or `Time`,

  This is the ISO8601 format with hours, minutes and optional seconds fields but
  with no "Z" as the identifier if the timezone offset is 0.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:utc_offset`
    and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `zone_iso/4`

  ## Format Symbol

  The representation of the `timezone offset` is made in accordance with the following
  table:

  | Symbol | Results        | Description                                                       |
  | :----  | :------------- | :---------------------------------------------------------------- |
  | x      | "+0100"        | ISO8601 Basic Format with hours and optional minutes              |
  | xx     | "-0800"        | ISO8601 Basic Format with hours and minutes                       |
  | xxx    | "+01:00"       | ISO8601 Extended Format with hours and minutes                    |
  | xxxx   | "+010059"      | ISO8601 Basic Format with hours and minutes, optional seconds     |
  | xxxxx  | "+01:00:10"    | ISO8601 Extended Format with hours and minutes, optional seconds  |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 1
      "+01"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 2
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 3
      "+01:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 4
      "+010010"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 5
      "+00:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 4
      "+0000"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 3
      "+00:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 2
      "+0000"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, 1
      "+00"

  """
  @iso_utc_offset_hours_minutes "+00:00"
  @spec zone_iso_z(Map.t, integer, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def zone_iso(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_iso(%{utc_offset: _offset, std_offset: _std_offset} = time, 1, _locale, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
    |> String.replace(~r/00\Z/, "")
  end

  def zone_iso(%{utc_offset: _offset, std_offset: _std_offset} = time, 2, _locale, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
  end

  def zone_iso(%{utc_offset: _offset, std_offset: _std_offset} = time, 3, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        @iso_utc_offset_hours_minutes
      {hours, minutes, _seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: 0}, format: :extended)
    end
  end

  def zone_iso(%{utc_offset: _offset, std_offset: _std_offset} = time, 4, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {hours, minutes, 0 = seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic) <> pad(seconds, 2)
    end
  end

  def zone_iso(%{utc_offset: _offset, std_offset: _std_offset} = time, 5, _locale, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, 0} ->
        @iso_utc_offset_hours_minutes
      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
    end
  end

  def zone_iso(time, _n, _locale, _options) do
    error_return(time, "x", [:utc_offset])
  end

  @doc """
  Returns the short localised GMT offset (format symbol `O`) part of a
  `DateTime` or `Time`.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the `:utc_offset`
    and `:std_offset` keys of the format used by `Time`

  * `n` is the specific non-location timezone format and is in the range `1..4`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `zone_gmt/4`

  ## Format Symbol

  The representation of the `GMT offset` is made in accordance with the following
  table:

  | Symbol | Results        | Description                                                     |
  | :----  | :------------- | :-------------------------------------------------------------- |
  | O      | "GMT+1"        | Short localised GMT format                                      |
  | OOOO   | "GMT+01:00"    | Long localised GMT format                                       |

  ## Examples

      iex> Cldr.DateTime.Formatter.zone_gmt %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 1
      "GMT+1"

      iex> Cldr.DateTime.Formatter.zone_gmt %{time_zone: "Etc/UTC", utc_offset: 3610, std_offset: 0}, 4
      "GMT+01:00"

  """
  def zone_gmt(time, n \\ 1, locale \\ Cldr.get_current_locale(), options \\ [])
  def zone_gmt(%{utc_offset: _offset, std_offset: _std_offset} = time, 1, locale, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    gmt_tz_format(locale, %{hour: hours, minute: minutes, second: seconds}, format: :short)
  end

  def zone_gmt(%{utc_offset: _offset, std_offset: _std_offset} = time, 4, locale, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    gmt_tz_format(locale, %{hour: hours, minute: minutes, second: seconds}, format: :long)
  end

  def zone_gmt(time, _n, _locale, _options) do
    error_return(time, "O", [:utc_offset])
  end

  @doc """
  Returns a literal.

  ## Example

      iex> Cldr.DateTime.Formatter.literal %{time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}, "A literal"
      "A literal"

  """
  @spec literal(any, binary, Cldr.Locale.t, Keyword.t) :: binary | {:error, binary}
  def literal(date, binary, locale \\ Cldr.get_current_locale, options \\ [])
  def literal(_date, binary, _locale, _options) do
    binary
  end

  # Helpers

  # Compile the formats used for timezones GMT format
  defp gmt_tz_format(locale, offset, options \\ [])

  for locale_name <- Cldr.known_locale_names do
    {:ok, gmt_format} = Cldr.DateTime.Format.gmt_format(locale_name)
    {:ok, gmt_zero_format} = Cldr.DateTime.Format.gmt_zero_format(locale_name)
    {:ok, {pos_format, neg_format}} = Cldr.DateTime.Format.hour_format(locale_name)
    {:ok, pos_transforms} = Compiler.compile(pos_format)
    {:ok, neg_transforms} = Compiler.compile(neg_format)

    defp gmt_tz_format(%LanguageTag{cldr_locale_name: unquote(locale_name)}, %{hour: 0, minute: 0}, _options) do
      unquote(gmt_zero_format)
    end

    defp gmt_tz_format(%LanguageTag{cldr_locale_name: unquote(locale_name)} = locale,
          %{hour: hour, minute: _minute} = date, options) when hour >= 0 do
      unquote(pos_transforms)
      |> gmt_format_type(options[:format] || :long)
      |> Cldr.Substitution.substitute(unquote(gmt_format))
      |> Enum.join
    end

    defp gmt_tz_format(%LanguageTag{cldr_locale_name: unquote(locale_name)} = locale,
          %{hour: _hour, minute: _minute} = date, options) do
      unquote(neg_transforms)
      |> gmt_format_type(options[:format] || :long)
      |> Cldr.Substitution.substitute(unquote(gmt_format))
      |> Enum.join
    end
  end

  # All of the 516 locales define an hour_format that have the following characteristics:
  #  >  :hour and :minute only (and always both)
  #  >  :minute is always 2 digits: "mm"
  #  >  always have a sign + or -
  #  >  have either a separator of ":", "." or no separator
  # Therefore the format is always either 4 parts (with separator) or 3 parts (without separator)

  # Short format with zero minutes
  defp gmt_format_type([sign, hour, _sep, "00"], :short) do
    :erlang.iolist_to_binary([sign, String.replace_leading(hour, "0", "")])
  end

  # Short format with minutes > 0
  defp gmt_format_type([sign, hour, sep, minute], :short) do
    :erlang.iolist_to_binary([sign, String.replace_leading(hour, "0", ""), sep, minute])
  end

  # Long format
  defp gmt_format_type([sign, hour, sep, minute], :long) do
    :erlang.iolist_to_binary([sign, hour, sep, minute])
  end

  # The case when there is no separator
  defp gmt_format_type([sign, hour, minute], format_type) do
    gmt_format_type([sign, hour, "", minute], format_type)
  end

  # ISO 8601 time zone formats:
  # The ISO 8601 basic format does not use a separator character between hours
  # and minutes field, while the extended format uses colon (':') as the
  # separator. The ISO 8601 basic format with hours and minutes fields is
  # equivalent to RFC 822 zone format.
  #
  # "-0800" (basic)
  # "-08" (basic - short)
  # "-08:00" (extended)
  # "Z" (UTC)
  defp iso8601_tz_format(%{hour: _hour, minute: _minute} = time, options) do
    iso8601_tz_format_type(time, options[:format] || :basic)
  end

  defp iso8601_tz_format_type(%{hour: 0, minute: 0}, :extended) do
    "Z"
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :basic) do
    sign(hour) <> hour(time, 2) <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :short) do
    sign(hour) <> hour(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :long) do
    sign(hour) <> hour(time, 2) <> ":" <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute, second: 0} = time, :extended) do
    sign(hour) <> hour(time, 2) <> ":" <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute, second: _second} = time, :extended) do
    sign(hour) <> hour(time, 2) <> ":" <> minute(time, 2) <> ":" <> second(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :extended) do
    sign(hour) <> hour(time, 2) <> ":" <> minute(time, 2)
  end

  defp sign(number) when number >= 0, do: "+"
  defp sign(_number), do: "-"

  defp get_era(%{calendar: calendar} = date, type, locale, nil) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    locale
    |> Cldr.Calendar.era(cldr_calendar)
    |> get_in([type, era_key(date, cldr_calendar, nil)])
  end

  defp get_era(%{calendar: calendar} = date, type, locale, :variant) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    era =
      locale
      |> Cldr.Calendar.era(cldr_calendar)
      |> get_in([type, era_key(date, cldr_calendar, :variant)])

    if era do
      era
    else
      get_era(date, type, locale, nil)
    end
  end

  defp era_key(date, calendar, variant) do
    index = Kalendar.era_number_from_date(date, calendar)
    if variant do
      :"#{index}_alt_#{variant}"
    else
      index
    end
  end

  defp get_period(locale, calendar, type, style, key, nil) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    locale
    |> Cldr.Calendar.period(cldr_calendar)
    |> get_in([type, style, key])
  end

  defp get_period(locale, calendar, type, style, key, :variant) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    period =
      locale
      |> Cldr.Calendar.period(cldr_calendar)
      |> get_in([type, style, :"#{key}_alt_variant"])

    if period do
      period
    else
      get_period(locale, calendar, type, style, key, nil)
    end
  end

  defp get_month(month, locale, calendar, type, style) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    locale
    |> Cldr.Calendar.month(cldr_calendar)
    |> get_in([type, style, month])
  end

  defp get_quarter(month, locale, calendar, type, style) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)

    locale
    |> Cldr.Calendar.quarter(cldr_calendar)
    |> get_in([type, style, month])
  end

  defp get_day(%{year: year, month: month, day: day, calendar: calendar}, locale, type, style) do
    {:ok, cldr_calendar} = type_from_calendar(calendar)
    day_of_week = Kalendar.day_key(calendar.day_of_week(year, month, day))

    locale
    |> Cldr.Calendar.day(cldr_calendar)
    |> get_in([type, style, day_of_week])
  end

  def type_from_calendar(calendar) do
    if :cldr_calendar in functions_exported(calendar) do
      {:ok, calendar.cldr_calendar}
    else
      {:ok, Kalendar.default_calendar}
    end
  end

  defp functions_exported(calendar) do
    Keyword.keys(calendar.__info__(:functions))
  end

  defp pad(integer, n) when integer >= 0 do
    padding = n - number_of_digits(integer)
    if padding <= 0 do
      Integer.to_string(integer)
    else
      :erlang.iolist_to_binary([List.duplicate(?0, padding), Integer.to_string(integer)])
    end
  end

  defp pad(integer, n) when integer < 0 do
    :erlang.iolist_to_binary([?-, pad(abs(integer), n)])
  end

  # This should be more performant than doing
  # Enum.count(Integer.digits(n)) for all cases
  defp number_of_digits(n) when n < 0, do: number_of_digits(abs(n))
  defp number_of_digits(n) when n < 10, do: 1
  defp number_of_digits(n) when n < 100, do: 2
  defp number_of_digits(n) when n < 1_000, do: 3
  defp number_of_digits(n) when n < 10_000, do: 4
  defp number_of_digits(n) when n < 100_000, do: 5
  defp number_of_digits(n) when n < 1_000_000, do: 6
  defp number_of_digits(n) when n < 10_000_000, do: 7
  defp number_of_digits(n) when n < 100_000_000, do: 8
  defp number_of_digits(n) when n < 1_000_000_000, do: 9
  defp number_of_digits(n) when n < 10_000_000_000, do: 10
  defp number_of_digits(n), do: Enum.count(Integer.digits(n))

  defp error_return(map, symbol, requirements) do
    {:error, "The format symbol '#{symbol}' requires at least #{inspect requirements}.  Found: #{inspect map}"}
  end

end