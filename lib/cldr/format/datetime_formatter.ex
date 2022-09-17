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
  |                        | ddd        | 2nd, 25th       | Ordinal day of month               |
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
  | AM or PM               | a, aa, aaa | "am."           | Abbreviated                        |
  |                        | aaaa       | "am."           | Wide                               |
  |                        | aaaaa      | "am"            | Narrow                             |
  | Noon, Mid, AM, PM      | b, bb, bbb | "mid."          | Abbreviated                        |
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
  | Milliseconds            | A+         | 4000, 63241     | Minimim digits of milliseconds since midnight |
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

  alias Cldr.DateTime.Timezone
  alias Cldr.Calendar.Gregorian
  alias Cldr.Locale
  alias Cldr.LanguageTag

  @type locale :: LanguageTag.t() | Locale.locale_name()

  @default_format 1

  @doc """
  Returns a formatted date.

  DateTime formats are defined in CLDR using substitution rules whereby
  the Date and/or Time are substituted into a format string.  Therefore
  this function crafts a date format string which is then inserted into
  the overall format being requested.

  """
  @spec date(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def date(date, n \\ @default_format, options \\ [])

  def date(date, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    date(date, @default_format, locale, backend, options)
  end

  def date(date, n, options) do
    {locale, backend} = extract_locale!(options)
    date(date, n, locale, backend, options)
  end

  @spec date(Calendar.date(), integer, locale(), Cldr.backend(), Keyword.t() | map()) ::
          String.t() | {:error, {module(), String.t()}}

  def date(date, _n, _locale, backend, options) when is_list(options) do
    with {:ok, date_string} <- Cldr.Date.to_string(date, backend, options) do
      date_string
    end
  end

  def date(date, n, locale, backend, options) when is_map(options) do
    date(date, n, locale, backend, Map.to_list(options))
  end

  @doc """
  Returns a formatted time.

  DateTime formats are defined in CLDR using substitution rules whereby
  the Date and/or Time are substituted into a format string.  Therefore
  this function crafts a time format string which is then inserted into
  the overall format being requested.

  """
  @spec time(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, {module(), String.t()}}

  def time(time, n \\ @default_format, options \\ [])

  def time(time, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    time(time, @default_format, locale, backend, options)
  end

  def time(time, n, options) do
    {locale, backend} = extract_locale!(options)
    time(time, n, locale, backend, options)
  end

  @spec time(Calendar.time(), integer, locale(), Cldr.backend(), Keyword.t() | map()) ::
          String.t() | {:error, String.t()}

  def time(time, _n, _locale, backend, options) when is_list(options) do
    with {:ok, time_string} <- Cldr.Time.to_string(time, backend, options) do
      time_string
    end
  end

  def time(time, n, locale, backend, options) when is_map(options) do
    time(time, n, locale, backend, Map.to_list(options))
  end

  @doc """
  Returns the `era` (format symbol `G`) of a date
  for given locale.

  ## Arguments

  * `date` is a `Date` struct or any map that contains at least the
    keys `:month` and `:calendar`

  * `n` in an integer between 1 and 5 that determines the format of
    the year

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.era ~D[2017-12-01], 1
      "AD"

      iex> Cldr.DateTime.Formatter.era ~D[2017-12-01], 4, "fr", MyApp.Cldr
      "après Jésus-Christ"

  """
  @spec era(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def era(era, n \\ @default_format, options \\ [])

  def era(era, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    era(era, @default_format, locale, backend, Map.new(options))
  end

  def era(era, n, options) do
    {locale, backend} = extract_locale!(options)
    era(era, n, locale, backend, Map.new(options))
  end

  @spec era(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def era(date, n, locale, backend, options \\ %{})

  def era(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> era(n, locale, backend, options)
  end

  def era(date, n, locale, backend, _options) when n in 1..3 do
    Cldr.Calendar.localize(date, :era, :format, :abbreviated, backend, locale)
  end

  def era(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :era, :format, :wide, backend, locale)
  end

  def era(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :era, :format, :narrow, backend, locale)
  end

  def era(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def year(year, n \\ @default_format, options \\ [])

  def year(year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    year(year, @default_format, locale, backend, Map.new(options))
  end

  def year(year, n, options) do
    {locale, backend} = extract_locale!(options)
    year(year, n, locale, backend, Map.new(options))
  end

  @spec year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def year(date, n, locale, backend, options \\ %{})

  def year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> year(n, locale, backend, options)
  end

  def year(%{year: _year} = date, 1, _locale, backend, options) do
    date
    |> Cldr.Calendar.calendar_year()
    |> transliterate("y", backend, options)
  end

  def year(%{year: _year} = date, 2 = n, _locale, backend, options) do
    date
    |> Cldr.Calendar.calendar_year()
    |> rem(100)
    |> transliterate("y", backend, options)
    |> pad(n)
  end

  def year(%{year: _year} = date, n, _locale, backend, options) do
    date
    |> Cldr.Calendar.calendar_year()
    |> transliterate("y", backend, options)
    |> pad(n)
  end

  def year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.week_aligned_year ~D[2017-01-04], 1
      "2017"

      iex> Cldr.DateTime.Formatter.week_aligned_year ~D[2017-01-04], 2
      "17"

      iex> Cldr.DateTime.Formatter.week_aligned_year ~D[2017-01-04], 3
      "2017"

      iex> Cldr.DateTime.Formatter.week_aligned_year ~D[2017-01-04], 4
      "2017"

      iex> Cldr.DateTime.Formatter.week_aligned_year ~D[2017-01-04], 5
      "02017"

  """
  @spec week_aligned_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def week_aligned_year(week_aligned_year, n \\ @default_format, options \\ [])

  def week_aligned_year(week_aligned_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    week_aligned_year(week_aligned_year, @default_format, locale, backend, Map.new(options))
  end

  def week_aligned_year(week_aligned_year, n, options) do
    {locale, backend} = extract_locale!(options)
    week_aligned_year(week_aligned_year, n, locale, backend, Map.new(options))
  end

  @spec week_aligned_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def week_aligned_year(date, n, locale, backend, options \\ %{})

  def week_aligned_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> week_aligned_year(n, locale, backend, options)
  end

  def week_aligned_year(date, 1, _locale, _backend, _options) do
    {year, _week} = Cldr.Calendar.week_of_year(date)
    to_string(year)
  end

  def week_aligned_year(date, 2 = n, _locale, _backend, _options) do
    {year, _week} = Cldr.Calendar.week_of_year(date)

    year
    |> rem(100)
    |> pad(n)
  end

  def week_aligned_year(date, n, _locale, _backend, _options) when n in 3..5 do
    {year, _week} = Cldr.Calendar.week_of_year(date)
    pad(year, n)
  end

  def week_aligned_year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec extended_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def extended_year(extended_year, n \\ @default_format, options \\ [])

  def extended_year(extended_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    extended_year(extended_year, @default_format, locale, backend, Map.new(options))
  end

  def extended_year(extended_year, n, options) do
    {locale, backend} = extract_locale!(options)
    extended_year(extended_year, n, locale, backend, Map.new(options))
  end

  @spec extended_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def extended_year(date, n, locale, backend, options \\ %{})

  def extended_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> extended_year(n, locale, backend, options)
  end

  def extended_year(%{year: year, calendar: Calendar.ISO}, n, _locale, _backend, _options) do
    pad(year, n)
  end

  def extended_year(%{year: year}, n, _locale, _backend, _options) do
    pad(year, n)
  end

  def extended_year(date, _n, _locale, _backend, _options) do
    error_return(date, "u", [:year, :calendar])
  end

  @doc """
  Returns the cyclic year (format symbol `U`) name for
  non-gregorian calendars.

  **NOTE: In the current implementation, the cyclic year is
  delegated to `Cldr.DateTime.Formatter.year/3`
  (format symbol `y`) and does not return a localized
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
  @spec cyclic_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def cyclic_year(cyclic_year, n \\ @default_format, options \\ [])

  def cyclic_year(cyclic_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    cyclic_year(cyclic_year, @default_format, locale, backend, Map.new(options))
  end

  def cyclic_year(cyclic_year, n, options) do
    {locale, backend} = extract_locale!(options)
    cyclic_year(cyclic_year, n, locale, backend, Map.new(options))
  end

  @spec cyclic_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def cyclic_year(date, n, locale, backend, options \\ %{})

  def cyclic_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> cyclic_year(n, locale, backend, options)
  end

  def cyclic_year(%{year: year}, _n, _locale, _backend, _options) do
    year
  end

  def cyclic_year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `related_year/4`

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
  @spec related_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def related_year(related_year, n \\ @default_format, options \\ [])

  def related_year(related_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    related_year(related_year, @default_format, locale, backend, Map.new(options))
  end

  def related_year(related_year, n, options) do
    {locale, backend} = extract_locale!(options)
    related_year(related_year, n, locale, backend, Map.new(options))
  end

  @spec related_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def related_year(date, n, locale, backend, options \\ %{})

  def related_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> related_year(n, locale, backend, options)
  end

  def related_year(%{year: year, calendar: Calendar.ISO}, _n, _locale, _backend, _options) do
    year
  end

  def related_year(%{year: year, calendar: Gregorian}, n, _locale, _backend, _options)
      when n in 1..5 do
    year
  end

  def related_year(date, n, _locale, _backend, _options) when n in 1..5 do
    date
    |> Date.convert!(Gregorian)
    |> Map.get(:year)
  end

  def related_year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `quarter/5`

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

      iex> Cldr.DateTime.Formatter.quarter ~D[2017-04-01], 1
      2

      iex> Cldr.DateTime.Formatter.quarter ~D[2017-04-01], 2
      "02"

      iex> Cldr.DateTime.Formatter.quarter ~D[2017-04-01], 3
      "Q2"

      iex> Cldr.DateTime.Formatter.quarter ~D[2017-04-01], 4
      "2nd quarter"

      iex> Cldr.DateTime.Formatter.quarter ~D[2017-04-01], 5
      "2"

  """
  @spec quarter(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def quarter(quarter, n \\ @default_format, options \\ [])

  def quarter(quarter, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    quarter(quarter, @default_format, locale, backend, Map.new(options))
  end

  def quarter(quarter, n, options) do
    {locale, backend} = extract_locale!(options)
    quarter(quarter, n, locale, backend, Map.new(options))
  end

  @spec quarter(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def quarter(date, n, locale, backend, options \\ %{})

  def quarter(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> quarter(n, locale, backend, options)
  end

  def quarter(date, 1, _locale, _backend, _options) do
    Cldr.Calendar.quarter_of_year(date)
  end

  def quarter(date, 2, _locale, _backend, _options) do
    date
    |> Cldr.Calendar.quarter_of_year()
    |> pad(2)
  end

  def quarter(date, 3, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :format, :abbreviated, backend, locale)
  end

  def quarter(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :format, :wide, backend, locale)
  end

  def quarter(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :format, :narrow, backend, locale)
  end

  def quarter(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `standalone_quarter/5`

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

      iex> Cldr.DateTime.Formatter.standalone_quarter ~D[2019-06-08], 1
      2

      iex> Cldr.DateTime.Formatter.standalone_quarter ~D[2019-06-08], 2
      "02"

      iex> Cldr.DateTime.Formatter.standalone_quarter ~D[2019-06-08], 3
      "Q2"

      iex> Cldr.DateTime.Formatter.standalone_quarter ~D[2019-06-08], 4
      "2nd quarter"

      iex> Cldr.DateTime.Formatter.standalone_quarter ~D[2019-06-08], 5
      "2"

  """
  @spec standalone_quarter(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def standalone_quarter(standalone_quarter, n \\ @default_format, options \\ [])

  def standalone_quarter(standalone_quarter, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    standalone_quarter(standalone_quarter, @default_format, locale, backend, Map.new(options))
  end

  def standalone_quarter(standalone_quarter, n, options) do
    {locale, backend} = extract_locale!(options)
    standalone_quarter(standalone_quarter, n, locale, backend, Map.new(options))
  end

  @spec standalone_quarter(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def standalone_quarter(date, n, locale, backend, options \\ %{})

  def standalone_quarter(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> standalone_quarter(n, locale, backend, options)
  end

  def standalone_quarter(date, 1, _locale, _backend, _options) do
    Cldr.Calendar.quarter_of_year(date)
  end

  def standalone_quarter(date, 2, _locale, _backend, _options) do
    date
    |> Cldr.Calendar.quarter_of_year()
    |> pad(2)
  end

  def standalone_quarter(date, 3, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :stand_alone, :abbreviated, backend, locale)
  end

  def standalone_quarter(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :stand_alone, :wide, backend, locale)
  end

  def standalone_quarter(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :quarter, :stand_alone, :narrow, backend, locale)
  end

  def standalone_quarter(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.month ~D[2019-09-08]
      "9"

      iex> Cldr.DateTime.Formatter.month ~D[2019-09-08], 2
      "09"

      iex> Cldr.DateTime.Formatter.month ~D[2019-09-08], 3
      "Sep"

      iex> Cldr.DateTime.Formatter.month ~D[2019-09-08], 4
      "September"

      iex> Cldr.DateTime.Formatter.month ~D[2019-09-08], 5
      "S"

  """
  @spec month(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def month(month, n \\ @default_format, options \\ [])

  def month(month, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    month(month, @default_format, locale, backend, Map.new(options))
  end

  def month(month, n, options) do
    {locale, backend} = extract_locale!(options)
    month(month, n, locale, backend, Map.new(options))
  end

  @spec month(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def month(date, n, locale, backend, options \\ %{})

  def month(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> month(n, locale, backend, options)
  end

  def month(%{month: _month} = date, n, locale, backend, _options) when n in 1..2 do
    date
    |> Cldr.Calendar.localize(:month, :numeric, :any, backend, locale)
    |> pad(n)
  end

  def month(date, 3, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :format, :abbreviated, backend, locale)
  end

  def month(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :format, :wide, backend, locale)
  end

  def month(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :format, :narrow, backend, locale)
  end

  def month(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.standalone_month ~D[2019-09-08]
      "9"

      iex> Cldr.DateTime.Formatter.standalone_month ~D[2019-09-08], 2
      "09"

      iex> Cldr.DateTime.Formatter.standalone_month ~D[2019-09-08], 3
      "Sep"

      iex> Cldr.DateTime.Formatter.standalone_month ~D[2019-09-08], 4
      "September"

      iex> Cldr.DateTime.Formatter.standalone_month ~D[2019-09-08], 5
      "S"

  """
  @spec standalone_month(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def standalone_month(standalone_month, n \\ @default_format, options \\ [])

  def standalone_month(standalone_month, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    standalone_month(standalone_month, @default_format, locale, backend, Map.new(options))
  end

  def standalone_month(standalone_month, n, options) do
    {locale, backend} = extract_locale!(options)
    standalone_month(standalone_month, n, locale, backend, Map.new(options))
  end

  @spec standalone_month(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def standalone_month(date, n, locale, backend, options \\ %{})

  def standalone_month(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> standalone_month(n, locale, backend, options)
  end

  def standalone_month(%{month: _month} = date, n, locale, backend, _options) when n in 1..2 do
    date
    |> Cldr.Calendar.localize(:month, :numeric, :any, backend, locale)
    |> pad(n)
  end

  def standalone_month(date, 3, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :stand_alone, :abbreviated, backend, locale)
  end

  def standalone_month(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :stand_alone, :wide, backend, locale)
  end

  def standalone_month(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :month, :stand_alone, :narrow, backend, locale)
  end

  def standalone_month(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> import Cldr.Calendar.Sigils
      Cldr.Calendar.Sigils
      iex> Cldr.DateTime.Formatter.week_of_year ~D[2019-01-07], 1
      "2"
      iex> Cldr.DateTime.Formatter.week_of_year ~d[2019-W04-1], 2
      "04"

  """
  @spec week_of_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def week_of_year(week_of_year, n \\ @default_format, options \\ [])

  def week_of_year(week_of_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    week_of_year(week_of_year, @default_format, locale, backend, Map.new(options))
  end

  def week_of_year(week_of_year, n, options) do
    {locale, backend} = extract_locale!(options)
    week_of_year(week_of_year, n, locale, backend, Map.new(options))
  end

  @spec week_of_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def week_of_year(date, n, locale, backend, options \\ %{})

  def week_of_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> week_of_year(n, locale, backend, options)
  end

  def week_of_year(date, n, _locale, _backend, _options) when n in 1..2 do
    {_year, week} = Cldr.Calendar.week_of_year(date)
    pad(week, n)
  end

  def week_of_year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `week_of_month/4`

  ## Format Symbol

  The representation of the week of the month is made in accordance
  with the following table:

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | W          | 2               |                 |

  ## Examples

      iex> import Cldr.Calendar.Sigils
      Cldr.Calendar.Sigils
      iex> Cldr.DateTime.Formatter.week_of_month ~D[2019-01-07], 1
      "2"
      iex> Cldr.DateTime.Formatter.week_of_month ~d[2019-W04-1], 1
      "4"

  """
  @spec week_of_month(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def week_of_month(week_of_month, n \\ @default_format, options \\ [])

  def week_of_month(week_of_month, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    week_of_month(week_of_month, @default_format, locale, backend, Map.new(options))
  end

  def week_of_month(week_of_month, n, options) do
    {locale, backend} = extract_locale!(options)
    week_of_month(week_of_month, n, locale, backend, Map.new(options))
  end

  @spec week_of_month(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def week_of_month(date, n, locale, backend, options \\ %{})

  def week_of_month(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> week_of_month(n, locale, backend, options)
  end

  def week_of_month(date, n, _locale, _backend, _options) when n in 1..2 do
    {_month, week_of_month} = Cldr.Calendar.week_of_month(date)
    pad(week_of_month, n)
  end

  def week_of_month(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options
    used in `day_of_month/4`

  ## Format Symbol

  The representation of the day of the month is made in accordance
  with the following table. Note that `ddd` is not part of the CLDR
  standard.

  | Symbol     | Example         | Cldr Format     |
  | :--------  | :-------------- | :-------------- |
  | d          | 2, 22           |                 |
  | dd         | 02, 22          |                 |
  | ddd        | 2nd, 22nd       |                 |

  ## Examples

      iex> Cldr.DateTime.Formatter.day_of_month ~D[2017-01-04], 1
      4

      iex> Cldr.DateTime.Formatter.day_of_month ~D[2017-01-04], 2
      "04"

      iex> Cldr.DateTime.Formatter.day_of_month ~D[2017-01-04], 3
      "4th"

  """
  @spec day_of_month(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def day_of_month(day_of_month, n \\ @default_format, options \\ [])

  def day_of_month(day_of_month, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    day_of_month(day_of_month, @default_format, locale, backend, Map.new(options))
  end

  def day_of_month(day_of_month, n, options) do
    {locale, backend} = extract_locale!(options)
    day_of_month(day_of_month, n, locale, backend, Map.new(options))
  end

  @spec day_of_month(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def day_of_month(date, n, locale, backend, options \\ %{})

  def day_of_month(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> day_of_month(n, locale, backend, options)
  end

  def day_of_month(%{day: day}, 1, _locale, backend, options) do
    day
    |> transliterate("d", backend, options)
  end

  def day_of_month(%{day: day}, 2, _locale, backend, options) do
    day
    |> transliterate("d", backend, options)
    |> pad(2)
  end

  def day_of_month(%{day: day}, 3, locale, backend, options) do
    day
    |> transliterate("d", backend, options)
    |> Cldr.Number.to_string!(backend, format: :ordinal, locale: locale)
  end

  def day_of_month(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.day_of_year ~D[2017-01-15], 1
      "15"

      iex> Cldr.DateTime.Formatter.day_of_year ~D[2017-01-15], 2
      "15"

      iex> Cldr.DateTime.Formatter.day_of_year ~D[2017-01-15], 3
      "015"

  """
  @spec day_of_year(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def day_of_year(day_of_year, n \\ @default_format, options \\ [])

  def day_of_year(day_of_year, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    day_of_year(day_of_year, @default_format, locale, backend, Map.new(options))
  end

  def day_of_year(day_of_year, n, options) do
    {locale, backend} = extract_locale!(options)
    day_of_year(day_of_year, n, locale, backend, Map.new(options))
  end

  @spec day_of_year(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def day_of_year(date, n, locale, backend, options \\ %{})

  def day_of_year(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> day_of_year(n, locale, backend, options)
  end

  def day_of_year(date, n, _locale, _backend, _options) when n in 1..3 do
    date
    |> Cldr.Calendar.day_of_year()
    |> pad(n)
  end

  def day_of_year(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 6
      "Tu"

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 5
      "T"

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 3
      "Tue"

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 2
      "Tue"

      iex> Cldr.DateTime.Formatter.day_name ~D[2017-08-15], 1
      "Tue"

  """
  @spec day_name(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def day_name(day_name, n \\ @default_format, options \\ [])

  def day_name(day_name, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    day_name(day_name, @default_format, locale, backend, Map.new(options))
  end

  def day_name(day_name, n, options) do
    {locale, backend} = extract_locale!(options)
    day_name(day_name, n, locale, backend, Map.new(options))
  end

  @spec day_name(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def day_name(date, n, locale, backend, options \\ %{})

  def day_name(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> day_name(n, locale, backend, options)
  end

  def day_name(date, n, locale, backend, _options) when n in 1..3 do
    Cldr.Calendar.localize(date, :day_of_week, :format, :abbreviated, backend, locale)
  end

  def day_name(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :format, :wide, backend, locale)
  end

  def day_name(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :format, :narrow, backend, locale)
  end

  def day_name(date, 6, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :format, :short, backend, locale)
  end

  def day_name(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 3
      "Tue"

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 5
      "T"

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 6
      "Tu"

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 1
      "2"

      iex> Cldr.DateTime.Formatter.day_of_week ~D[2017-08-15], 2
      "02"

  """
  @spec day_of_week(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def day_of_week(day_of_week, n \\ @default_format, options \\ [])

  def day_of_week(day_of_week, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    day_of_week(day_of_week, @default_format, locale, backend, Map.new(options))
  end

  def day_of_week(day_of_week, n, options) do
    {locale, backend} = extract_locale!(options)
    day_of_week(day_of_week, n, locale, backend, Map.new(options))
  end

  @spec day_of_week(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def day_of_week(date, n, locale, backend, options \\ %{})

  def day_of_week(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> day_of_week(n, locale, backend, options)
  end

  def day_of_week(date, n, _locale, _backend, _options) when n in 1..2 do
    date
    |> Cldr.Calendar.day_of_week()
    |> pad(n)
  end

  def day_of_week(date, n, locale, backend, options) when n >= 3 do
    day_name(date, n, locale, backend, options)
  end

  def day_of_week(date, _n, _locale, _backend, _options) do
    error_return(date, "e", [:year, :month, :day, :calendar])
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.standalone_day_of_week ~D[2017-08-15], 3
      "Tue"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week ~D[2017-08-15], 4
      "Tuesday"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week ~D[2017-08-15], 5
      "T"

      iex> Cldr.DateTime.Formatter.standalone_day_of_week ~D[2017-08-15], 6
      "Tu"

  """
  @spec standalone_day_of_week(Calendar.date(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def standalone_day_of_week(standalone_day_of_week, n \\ @default_format, options \\ [])

  def standalone_day_of_week(standalone_day_of_week, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    standalone_day_of_week(standalone_day_of_week, @default_format, locale, backend, Map.new(options))
  end

  def standalone_day_of_week(standalone_day_of_week, n, options) do
    {locale, backend} = extract_locale!(options)
    standalone_day_of_week(standalone_day_of_week, n, locale, backend, Map.new(options))
  end

  @spec standalone_day_of_week(Calendar.date(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def standalone_day_of_week(date, n, locale, backend, options \\ %{})

  def standalone_day_of_week(%{calendar: Calendar.ISO} = date, n, locale, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> standalone_day_of_week(n, locale, backend, options)
  end

  def standalone_day_of_week(date, n, _locale, _backend, _options) when n in 1..2 do
    date
    |> Cldr.Calendar.day_of_week()
    |> pad(n)
  end

  def standalone_day_of_week(date, 3, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :stand_alone, :abbreviated, backend, locale)
  end

  def standalone_day_of_week(date, 4, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :stand_alone, :wide, backend, locale)
  end

  def standalone_day_of_week(date, 5, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :stand_alone, :narrow, backend, locale)
  end

  def standalone_day_of_week(date, 6, locale, backend, _options) do
    Cldr.Calendar.localize(date, :day_of_week, :stand_alone, :short, backend, locale)
  end

  def standalone_day_of_week(date, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

  """
  @spec period_am_pm(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def period_am_pm(period_am_pm, n \\ @default_format, options \\ [])

  def period_am_pm(period_am_pm, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    period_am_pm(period_am_pm, @default_format, locale, backend, Map.new(options))
  end

  def period_am_pm(period_am_pm, n, options) do
    {locale, backend} = extract_locale!(options)
    period_am_pm(period_am_pm, n, locale, backend, Map.new(options))
  end

  @spec period_am_pm(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def period_am_pm(time, n, locale, backend, options \\ %{})

  def period_am_pm(time, n, locale, backend, _options) when n in 1..3 do
    Cldr.Calendar.localize(time, :am_pm, :format, :abbreviated, backend, locale)
  end

  def period_am_pm(time, 4, locale, backend, _options) do
    Cldr.Calendar.localize(time, :am_pm, :format, :wide, backend, locale)
  end

  def period_am_pm(time, 5, locale, backend, _options) do
    Cldr.Calendar.localize(time, :am_pm, :format, :narrow, backend, locale)
  end

  def period_am_pm(time, _n, _locale, _backend, _options) do
    error_return(time, "a", [:hour])
  end

  @doc """
  Returns the formatting of the time period as either
  `noon`, `midnight` or `am`/`pm` (format symbol 'b').

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the
    key `:second`

  * `n` in an integer between 1 and 5 that determines the format of the
    time period

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  The available option is
    `period: :variant` which will use a variant of localised "noon" and
    "midnight" if one is available

  ## Notes

  If the language doesn't support "noon" or "midnight" then
  `am`/`pm` is used for all time periods.

  May be upper or lowercase depending on the locale and other options.
  If the locale doesn't have the notion of a unique `noon == 12:00`,
  then the PM form may be substituted. Similarly for `midnight == 00:00`
  and the AM form.

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
      "in the morning"

      iex> Cldr.DateTime.Formatter.period_noon_midnight %{hour: 16, minute: 0}
      "PM"

  """
  @spec period_noon_midnight(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def period_noon_midnight(period_noon_midnight, n \\ @default_format, options \\ [])

  def period_noon_midnight(period_noon_midnight, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    period_noon_midnight(period_noon_midnight, @default_format, locale, backend, Map.new(options))
  end

  def period_noon_midnight(period_noon_midnight, n, options) do
    {locale, backend} = extract_locale!(options)
    period_noon_midnight(period_noon_midnight, n, locale, backend, Map.new(options))
  end

  @spec period_noon_midnight(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def period_noon_midnight(time, n, locale, backend, options \\ %{})

  def period_noon_midnight(%{hour: hour, minute: minute} = time, n, locale, backend, options)
      when (rem(hour, 12) == 0 or rem(hour, 24) < 12) and minute == 0 do
    format_backend = Module.concat(backend, DateTime.Format)

    if format_backend.language_has_noon_and_midnight?(locale) do
      day_period = format_backend.day_period_for(time, locale.language)
      Cldr.Calendar.localize(day_period, :day_periods, :format, period_format(n), backend, locale)
    else
      period_am_pm(time, n, locale, backend, options)
    end
  end

  def period_noon_midnight(%{hour: _hour, minute: _minute} = time, n, locale, backend, options) do
    period_am_pm(time, n, locale, backend, options)
  end

  def period_noon_midnight(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec period_flex(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def period_flex(period_flex, n \\ @default_format, options \\ [])

  def period_flex(period_flex, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    period_flex(period_flex, @default_format, locale, backend, Map.new(options))
  end

  def period_flex(period_flex, n, options) do
    {locale, backend} = extract_locale!(options)
    period_flex(period_flex, n, locale, backend, Map.new(options))
  end

  @spec period_flex(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def period_flex(time, n, locale, backend, options \\ %{})

  def period_flex(%{hour: _hour, minute: _minute} = time, n, locale, backend, _options) do
    format_backend = Module.concat(backend, DateTime.Format)
    day_period = format_backend.day_period_for(time, locale)
    Cldr.Calendar.localize(day_period, :day_periods, :format, period_format(n), backend, locale)
  end

  def period_flex(time, _n, _locale, _backend, _options) do
    error_return(time, "B", [:hour, :minute])
  end

  defp period_format(n) when n in 1..3, do: :abbreviated
  defp period_format(4), do: :wide
  defp period_format(5), do: :narrow

  @doc """
  Returns the hour formatted in a locale-specific format

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:hour`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `hour/4`

  ## Examples

      iex> Cldr.DateTime.Formatter.hour ~N[2020-04-25 15:00:00.0]
      "3"

      iex> Cldr.DateTime.Formatter.hour ~N[2020-04-25 15:00:00.0], locale: "fr"
      "15"

      iex> Cldr.DateTime.Formatter.hour ~N[2020-04-25 15:00:00.0], locale: "en-AU"
      "3"

      iex> Cldr.DateTime.Formatter.hour ~N[2020-04-25 15:00:00.0], locale: "en-AU-u-hc-h23"
      "15"

  """
  @spec hour(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def hour(hour, n \\ @default_format, options \\ [])

  def hour(hour, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    hour(hour, @default_format, locale, backend, Map.new(options))
  end

  def hour(hour, n, options) do
    {locale, backend} = extract_locale!(options)
    hour(hour, n, locale, backend, Map.new(options))
  end

  @spec hour(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def hour(time, n, locale, backend, options \\ %{})

  def hour(hour, n, locale, backend, options) do
    hour_formatter = Cldr.Time.hour_format_from_locale(locale)
    apply(__MODULE__, hour_formatter, [hour, n, locale, backend, options])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `h`) as a number in the
  range 1..12 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:hour`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `h12/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   h     |  12   | 1...11  |  12  |  1...11    |  12   |

  ## Examples

      iex> Cldr.DateTime.Formatter.h12 %{hour: 0}
      "12"

      iex> Cldr.DateTime.Formatter.h12 %{hour: 12}
      "12"

      iex> Cldr.DateTime.Formatter.h12 %{hour: 24}
      "12"

      iex> Cldr.DateTime.Formatter.h12 %{hour: 11}
      "11"

      iex> Cldr.DateTime.Formatter.h12 %{hour: 23}
      "11"

  """
  @spec h12(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def h12(h12, n \\ @default_format, options \\ [])

  def h12(h12, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    h12(h12, @default_format, locale, backend, Map.new(options))
  end

  def h12(h12, n, options) do
    {locale, backend} = extract_locale!(options)
    h12(h12, n, locale, backend, Map.new(options))
  end

  @spec h12(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def h12(time, n, locale, backend, options \\ %{})

  def h12(%{hour: hour}, n, _locale, _backend, _options) when hour in [0, 12, 24] do
    12
    |> pad(n)
  end

  def h12(%{hour: hour}, n, _locale, _backend, _options) when hour in 1..11 do
    hour
    |> pad(n)
  end

  def h12(%{hour: hour}, n, _locale, _backend, _options) when hour in 13..23 do
    (hour - 12)
    |> pad(n)
  end

  def h12(time, _n, _locale, _backend, _options) do
    error_return(time, "h", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `K`) as a number in the
  range 0..11 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:hour`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `h11/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   K     |   0   | 1...11  |   0  |  1...11    |   0   |

  ## Examples

      iex> Cldr.DateTime.Formatter.h11 %{hour: 0}
      "0"

      iex> Cldr.DateTime.Formatter.h11 %{hour: 12}
      "0"

      iex> Cldr.DateTime.Formatter.h11 %{hour: 24}
      "0"

      iex> Cldr.DateTime.Formatter.h11 %{hour: 23}
      "11"

      iex> Cldr.DateTime.Formatter.h11 %{hour: 11}
      "11"

      iex> Cldr.DateTime.Formatter.h11 %{hour: 9}
      "9"

  """
  @spec h11(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def h11(h11, n \\ @default_format, options \\ [])

  def h11(h11, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    h11(h11, @default_format, locale, backend, Map.new(options))
  end

  def h11(h11, n, options) do
    {locale, backend} = extract_locale!(options)
    h11(h11, n, locale, backend, Map.new(options))
  end

  @spec h11(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def h11(time, n, locale, backend, options \\ %{})

  def h11(%{hour: hour}, n, _locale, _backend, _options) when hour in [0, 12, 24] do
    0
    |> pad(n)
  end

  def h11(%{hour: hour}, n, _locale, _backend, _options) when hour in 1..11 do
    hour
    |> pad(n)
  end

  def h11(%{hour: hour}, n, _locale, _backend, _options) when hour in 13..23 do
    (hour - 12)
    |> pad(n)
  end

  def h11(time, _n, _locale, _backend, _options) do
    error_return(time, "K", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `k`) as a number in the
  range 1..24 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:hour`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `h24/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   k     |  24   | 1...11  |  12  |  13...23   |  24   |

  ## Examples

      iex(4)> Cldr.DateTime.Formatter.h24 %{hour: 0}
      "24"

      iex(5)> Cldr.DateTime.Formatter.h24 %{hour: 12}
      "12"

      iex(6)> Cldr.DateTime.Formatter.h24 %{hour: 13}
      "13"

      iex(7)> Cldr.DateTime.Formatter.h24 %{hour: 9}
      "9"

      iex(8)> Cldr.DateTime.Formatter.h24 %{hour: 24}
      "24"

  """
  @spec h24(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def h24(h24, n \\ @default_format, options \\ [])

  def h24(h24, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    h24(h24, @default_format, locale, backend, Map.new(options))
  end

  def h24(h24, n, options) do
    {locale, backend} = extract_locale!(options)
    h24(h24, n, locale, backend, Map.new(options))
  end

  @spec h24(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def h24(time, n, locale, backend, options \\ %{})

  def h24(%{hour: hour}, n, _locale, _backend, _options) when hour in [0, 24] do
    24
    |> pad(n)
  end

  def h24(%{hour: hour}, n, _locale, _backend, _options) when hour in 1..23 do
    hour
    |> pad(n)
  end

  def h24(time, _n, _locale, _backend, _options) do
    error_return(time, "k", [:hour])
  end

  @doc """
  Returns the formatting of the `:hour` (format symbol `H`) as a number
  in the range 0..23 as a string.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:hour`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `h23/4`

  ## Format Symbol

  The representation of the `hour` is made in accordance with the following
  table:

  | Symbol  | Midn.	|	Morning	| Noon |	Afternoon	| Midn. |
  | :----:  | :---: | :-----: | :--: | :--------: | :---: |
  |   H     |   0   | 1...11  |  12  |  13...23   |   0   |

  ## Examples:

      iex> Cldr.DateTime.Formatter.h23 %{hour: 10}
      "10"

      iex> Cldr.DateTime.Formatter.h23 %{hour: 13}
      "13"

      iex> Cldr.DateTime.Formatter.h23 %{hour: 21}
      "21"

      iex> Cldr.DateTime.Formatter.h23 %{hour: 24}
      "0"

      iex> Cldr.DateTime.Formatter.h23 %{hour: 0}
      "0"

  """
  @spec h23(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def h23(h23, n \\ @default_format, options \\ [])

  def h23(h23, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    h23(h23, @default_format, locale, backend, Map.new(options))
  end

  def h23(h23, n, options) do
    {locale, backend} = extract_locale!(options)
    h23(h23, n, locale, backend, Map.new(options))
  end

  @spec h23(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def h23(time, n, locale, backend, options \\ %{})

  def h23(%{hour: hour}, n, _locale, _backend, _options) when abs(hour) in [0, 24] do
    0
    |> pad(n)
  end

  def h23(%{hour: hour}, n, _locale, _backend, _options) when abs(hour) in 1..23 do
    abs(hour)
    |> pad(n)
  end

  def h23(time, _n, _locale, _backend, _options) do
    error_return(time, "H", [:hour])
  end

  @doc """
  Returns the `:minute` of a `time` or `datetime` (format symbol `m`) as number
  in string format.  The number of `m`'s in the format determines the formatting.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:minute`

  * `n` is the number of digits to which `:minute` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec minute(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def minute(minute, n \\ @default_format, options \\ [])

  def minute(minute, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    minute(minute, @default_format, locale, backend, Map.new(options))
  end

  def minute(minute, n, options) do
    {locale, backend} = extract_locale!(options)
    minute(minute, n, locale, backend, Map.new(options))
  end

  @spec minute(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def minute(time, n, locale, backend, options \\ %{})

  def minute(%{minute: minute}, 1, _locale, _backend, _options) do
    minute
  end

  def minute(%{minute: minute}, 2 = n, _locale, _backend, _options) do
    minute
    |> pad(n)
  end

  def minute(time, _n, _locale, _backend, _options) do
    error_return(time, "m", [:minute])
  end

  @doc """
  Returns the `:second` of a `time` or `datetime` (format symbol `s`) as number
  in string format.  The number of `s`'s in the format determines the formatting.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`

  * `n` is the number of digits to which `:hour` is padded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec second(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def second(second, n \\ @default_format, options \\ [])

  def second(second, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    second(second, @default_format, locale, backend, Map.new(options))
  end

  def second(second, n, options) do
    {locale, backend} = extract_locale!(options)
    second(second, n, locale, backend, Map.new(options))
  end

  @spec second(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def second(time, n, locale, backend, options \\ %{})

  def second(%{second: second}, n, _locale, _backend, _options) do
    second
    |> pad(n)
  end

  def second(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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
  @spec fractional_second(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def fractional_second(fractional_second, n \\ @default_format, options \\ [])

  def fractional_second(fractional_second, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    fractional_second(fractional_second, @default_format, locale, backend, Map.new(options))
  end

  def fractional_second(fractional_second, n, options) do
    {locale, backend} = extract_locale!(options)
    fractional_second(fractional_second, n, locale, backend, Map.new(options))
  end

  @spec fractional_second(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  # Note that TR35 says we should truncate the number of decimal digits
  # but we are rounding
  def fractional_second(time, n, locale, backend, options \\ %{})

  @microseconds 1_000_000
  def fractional_second(
        %{second: second, microsecond: {fraction, resolution}},
        n,
        _locale,
        _backend,
        _options
      ) do
    rounding = min(resolution, n)

    (second * 1.0 + fraction / @microseconds)
    |> Float.round(rounding)
    |> to_string
  end

  def fractional_second(%{second: second}, n, _locale, _backend, _options) do
    second
    |> pad(n)
  end

  def fractional_second(time, _n, _locale, _backend, _options) do
    error_return(time, "S", [:second])
  end

  @doc """
  Returns the `time` (format symbol `A`) as milliseconds since
  midnight.

  ## Arguments

  * `time` is a `Time` struct or any map that contains at least the key `:second`
    with and optional `:microsecond` key of the format used by `Time`

  * `n` is the number of fractional digits to which the float number of seconds
    is rounded

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  * `options` is a `Keyword` list of options.  There are no options used in
    `millisecond/4`

  ## Format Symbol

  The representation of the `milliseconds` is made in accordance with the following
  table:

  | Symbol | Results    | Description                                             |
  | :----  | :--------- | :------------------------------------------------------ |
  | A+     | "4000"     | Minimum necessary digits of milliseconds since midnight |

  ## Examples

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 0, minute: 0,
      ...>   second: 4, microsecond: {2000, 3}}, 1
      "4002"

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 0, minute: 0, second: 4}, 1
      "4000"

      iex> Cldr.DateTime.Formatter.millisecond %{hour: 10, minute: 10, second: 4}, 1
      "36604000"

      iex> Cldr.DateTime.Formatter.millisecond ~T[07:35:13.215217]
      "27313215"

  """
  @spec millisecond(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def millisecond(millisecond, n \\ @default_format, options \\ [])

  def millisecond(millisecond, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    millisecond(millisecond, @default_format, locale, backend, Map.new(options))
  end

  def millisecond(millisecond, n, options) do
    {locale, backend} = extract_locale!(options)
    millisecond(millisecond, n, locale, backend, Map.new(options))
  end

  @milliseconds 1_000
  @spec millisecond(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def millisecond(time, n, locale, backend, options \\ %{})

  def millisecond(
        %{hour: hour, minute: minute, second: second, microsecond: {fraction, _resolution}},
        n,
        _locale,
        _backend,
        _options
      ) do
    (rem(hour, 24) * @milliseconds * 60 * 60 + minute * @milliseconds * 60 +
       second * @milliseconds + div(fraction, @milliseconds))
    |> pad(n)
  end

  def millisecond(%{hour: hour, minute: minute, second: second}, n, _locale, _backend, _options) do
    (rem(hour, 24) * @milliseconds * 60 * 60 + minute * @milliseconds * 60 +
       second * @milliseconds)
    |> pad(n)
  end

  def millisecond(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_generic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 4
      "GMT"

      iex> Cldr.DateTime.Formatter.zone_generic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 1
      "Etc/UTC"

  """
  @spec zone_generic(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_generic(zone_generic, n \\ @default_format, options \\ [])

  def zone_generic(zone_generic, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_generic(zone_generic, @default_format, locale, backend, Map.new(options))
  end

  def zone_generic(zone_generic, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_generic(zone_generic, n, locale, backend, Map.new(options))
  end

  @spec zone_generic(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_generic(time, n, locale, backend, options \\ %{})

  def zone_generic(%{time_zone: time_zone}, 1, _locale, _backend, _options) do
    time_zone
  end

  def zone_generic(time, 4, locale, backend, options) do
    zone_id(time, 4, locale, backend, options)
  end

  def zone_generic(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_short %{zone_abbr: "UTC",
      ...>   utc_offset: 0, std_offset: 0}, 1
      "UTC"

      iex> Cldr.DateTime.Formatter.zone_short %{zone_abbr: "UTC",
      ...>   utc_offset: 0, std_offset: 0}, 4
      "GMT"

  """
  @spec zone_short(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_short(zone_short, n \\ @default_format, options \\ [])

  def zone_short(zone_short, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_short(zone_short, @default_format, locale, backend, Map.new(options))
  end

  def zone_short(zone_short, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_short(zone_short, n, locale, backend, Map.new(options))
  end

  @spec zone_short(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_short(time, n, locale, backend, options \\ %{})

  def zone_short(%{zone_abbr: zone_abbr}, n, _locale, _backend, _options) when n in 1..3 do
    zone_abbr
  end

  def zone_short(%{zone_abbr: _zone_abbr} = time, 4 = n, locale, backend, options) do
    zone_gmt(time, n, locale, backend, options)
  end

  def zone_short(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 1
      "unk"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 2
      "Etc/UTC"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 3
      "Unknown City"

      iex> Cldr.DateTime.Formatter.zone_id %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 4
      "GMT"

  """
  @spec zone_id(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_id(zone_id, n \\ @default_format, options \\ [])

  def zone_id(zone_id, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_id(zone_id, @default_format, locale, backend, Map.new(options))
  end

  def zone_id(zone_id, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_id(zone_id, n, locale, backend, Map.new(options))
  end

  @spec zone_id(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_id(time, n, locale, backend, options \\ %{})

  def zone_id(%{time_zone: _time_zone}, 1, _locale, _backend, _options) do
    "unk"
  end

  def zone_id(%{time_zone: time_zone}, 2, _locale, _backend, _options) do
    time_zone
  end

  def zone_id(%{time_zone: _time_zone}, 3, _locale, _backend, _options) do
    "Unknown City"
  end

  def zone_id(%{time_zone: _time_zone} = time, 4, locale, backend, options) do
    zone_gmt(time, 4, locale, backend, options)
  end

  def zone_id(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3600, std_offset: 0}, 1
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 4
      "GMT+01:00"

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 5
      "Z"

      iex> Cldr.DateTime.Formatter.zone_basic %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

  """
  @spec zone_basic(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_basic(zone_basic, n \\ @default_format, options \\ [])

  def zone_basic(zone_basic, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_basic(zone_basic, @default_format, locale, backend, Map.new(options))
  end

  def zone_basic(zone_basic, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_basic(zone_basic, n, locale, backend, Map.new(options))
  end

  @spec zone_basic(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_basic(time, n, locale, backend, options \\ %{})

  def zone_basic(time, n, _locale, _backend, _options) when n in 1..3 do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
  end

  def zone_basic(time, 4 = n, locale, backend, options) do
    zone_gmt(time, n, locale, backend, options)
  end

  def zone_basic(time, 5, _locale, _backend, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
  end

  def zone_basic(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 1
      "+01"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 2
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 3
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 4
      "+010010"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 5
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 4
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 3
      "Z"

      iex> Cldr.DateTime.Formatter.zone_iso_z %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 2
      "Z"

  """
  @spec zone_iso_z(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_iso_z(zone_iso_z, n \\ @default_format, options \\ [])

  def zone_iso_z(zone_iso_z, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_iso_z(zone_iso_z, @default_format, locale, backend, Map.new(options))
  end

  def zone_iso_z(zone_iso_z, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_iso_z(zone_iso_z, n, locale, backend, Map.new(options))
  end

  @spec zone_iso_z(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_iso_z(time, n, locale, backend, options \\ %{})

  def zone_iso_z(time, 1, _locale, _backend, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"

      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
        |> String.replace(~r/00\Z/, "")
    end
  end

  def zone_iso_z(time, 2, _locale, _backend, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"

      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
    end
  end

  def zone_iso_z(time, 3, _locale, _backend, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"

      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
    end
  end

  def zone_iso_z(time, 4, _locale, _backend, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"

      {hours, minutes, 0 = seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)

      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic) <>
          pad(seconds, 2)
    end
  end

  def zone_iso_z(time, 5, _locale, _backend, _options) do
    case Timezone.time_from_zone_offset(time) do
      {0, 0, _} ->
        "Z"

      {hours, minutes, seconds} ->
        iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
    end
  end

  def zone_iso_z(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 1
      "+01"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 2
      "+0100"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 3
      "+01:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 4
      "+010010"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 5
      "+01:00:10"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 5
      "+00:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 4
      "+0000"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 3
      "+00:00"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 2
      "+0000"

      iex> Cldr.DateTime.Formatter.zone_iso %{time_zone: "Etc/UTC",
      ...>   utc_offset: 0, std_offset: 0}, 1
      "+00"

  """
  @spec zone_iso(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_iso(zone_iso, n \\ @default_format, options \\ [])

  def zone_iso(zone_iso, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_iso(zone_iso, @default_format, locale, backend, Map.new(options))
  end

  def zone_iso(zone_iso, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_iso(zone_iso, n, locale, backend, Map.new(options))
  end

  @iso_utc_offset_hours_minutes "+00:00"
  @spec zone_iso(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_iso(time, n, locale, backend, options \\ %{})

  def zone_iso(time, 1, _locale, _backend, _options) do
    with {hours, minutes, seconds} <- Timezone.time_from_zone_offset(time) do
      iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
      |> String.replace(~r/00\Z/, "")
    end
  end

  def zone_iso(time, 2, _locale, _backend, _options) do
    with {hours, minutes, seconds} = Timezone.time_from_zone_offset(time) do
      iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)
    end
  end

  def zone_iso(time, 3, _locale, _backend, _options) do
    with {hours, minutes, seconds} <- Timezone.time_from_zone_offset(time) do
      case {hours, minutes, seconds} do
        {0, 0, _} ->
          @iso_utc_offset_hours_minutes

        {hours, minutes, _seconds} ->
          iso8601_tz_format(%{hour: hours, minute: minutes, second: 0}, format: :extended)
      end
    end
  end

  def zone_iso(time, 4, _locale, _backend, _options) do
    with {hours, minutes, seconds} <- Timezone.time_from_zone_offset(time) do
      case {hours, minutes, seconds} do
        {hours, minutes, 0 = seconds} ->
          iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic)

        {hours, minutes, seconds} ->
          iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :basic) <>
            pad(seconds, 2)
      end
    end
  end

  def zone_iso(time, 5, _locale, _backend, _options) do
    with {hours, minutes, seconds} <- Timezone.time_from_zone_offset(time) do
      case {hours, minutes, seconds} do
        {0, 0, 0} ->
          @iso_utc_offset_hours_minutes

        {hours, minutes, seconds} ->
          iso8601_tz_format(%{hour: hours, minute: minutes, second: seconds}, format: :extended)
      end
    end
  end

  def zone_iso(time, _n, _locale, _backend, _options) do
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
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

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

      iex> Cldr.DateTime.Formatter.zone_gmt %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 1
      "GMT+1"

      iex> Cldr.DateTime.Formatter.zone_gmt %{time_zone: "Etc/UTC",
      ...>   utc_offset: 3610, std_offset: 0}, 4
      "GMT+01:00"

  """
  @spec zone_gmt(Calendar.time(), integer, Keyword.t()) ::
          String.t() | {:error, String.t()}

  def zone_gmt(zone_gmt, n \\ @default_format, options \\ [])

  def zone_gmt(zone_gmt, options, []) when is_list(options) do
    {locale, backend} = extract_locale!(options)
    zone_gmt(zone_gmt, @default_format, locale, backend, Map.new(options))
  end

  def zone_gmt(zone_gmt, n, options) do
    {locale, backend} = extract_locale!(options)
    zone_gmt(zone_gmt, n, locale, backend, Map.new(options))
  end

  @spec zone_gmt(Calendar.time(), integer, locale(), Cldr.backend(), map()) ::
          String.t() | {:error, String.t()}

  def zone_gmt(time, n, locale, backend, options \\ %{})

  def zone_gmt(time, 1, locale, backend, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    backend = Module.concat(backend, DateTime.Formatter)

    backend.gmt_tz_format(locale, %{hour: hours, minute: minutes, second: seconds}, format: :short)
  end

  def zone_gmt(time, 4, locale, backend, _options) do
    {hours, minutes, seconds} = Timezone.time_from_zone_offset(time)
    backend = Module.concat(backend, DateTime.Formatter)
    backend.gmt_tz_format(locale, %{hour: hours, minute: minutes, second: seconds}, format: :long)
  end

  def zone_gmt(time, _n, _locale, _backend, _options) do
    error_return(time, "O", [:utc_offset])
  end

  @doc """
  Returns a literal.

  ## Example

      iex> Cldr.DateTime.Formatter.literal %{time_zone:
      ...>   "Etc/UTC", utc_offset: 0, std_offset: 0}, "A literal"
      "A literal"

  """
  @spec literal(any(), String.t(), Keyword.t()) :: String.t()

  def literal(date, literal, options \\ []) do
    {locale, backend} = extract_locale!(options)
    literal(date, literal, locale, backend, Map.new(options))
  end

  @spec literal(any(), String.t(), locale(), Cldr.backend(), map()) :: String.t()

  def literal(_date, binary, locale, backend, options \\ %{})

  def literal(_date, binary, _locale, _backend, _options) do
    binary
  end

  # Helpers

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
    sign(hour) <> h23(time, 2) <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :short) do
    sign(hour) <> h23(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :long) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute, second: 0} = time, :extended) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute, second: _second} = time, :extended) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2) <> ":" <> second(time, 2)
  end

  defp iso8601_tz_format_type(%{hour: hour, minute: _minute} = time, :extended) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  defp sign(number) when number >= 0, do: "+"
  defp sign(_number), do: "-"

  defp pad(integer, n) when is_integer(integer) and integer >= 0 do
    padding = n - number_of_digits(integer)

    if padding <= 0 do
      Integer.to_string(integer)
    else
      :erlang.iolist_to_binary([List.duplicate(?0, padding), Integer.to_string(integer)])
    end
  end

  defp pad(integer, n) when is_integer(integer) and integer < 0 do
    :erlang.iolist_to_binary([?-, pad(abs(integer), n)])
  end

  defp pad(integer, n) when is_binary(integer) do
    len = String.length(integer)
    if len >= n do
      integer
    else
      String.duplicate("0", n - len) <> integer
    end
  end

  # This should be more performant than doing
  # Enum.count(Integer.digits(n)) for all cases
  # defp number_of_digits(n) when n < 0, do: number_of_digits(abs(n))
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

  @doc false
  def error_return(map, symbol, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> join_requirements

    raise Cldr.DateTime.UnresolvedFormat,
          "The format symbol '#{symbol}' requires at map with at least #{requirements}. Found: #{inspect(map)}"
  end

  @doc false
  def join_requirements([]) do
    ""
  end

  def join_requirements([head]) do
    head
  end

  def join_requirements([head, tail]) do
    "#{head} and #{tail}"
  end

  def join_requirements([head | tail]) do
    to_string(head) <> ", " <> join_requirements(tail)
  end

  defp extract_locale!(options) do
    locale = Keyword.get(options, :locale, Cldr.get_locale())
    backend = Keyword.get(options, :backend)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend) do
      {locale, backend || locale.backend}
    else
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  # Transliterate a string for a specific format code

  defp transliterate(number, format_code, backend, %{_number_systems: number_systems}) do
    if number_system = Map.get(number_systems, format_code) do
      Cldr.Number.System.to_system!(number, number_system, backend)
    else
      number
    end
  end

  defp transliterate(number, _format_code, _backend, _options) do
    number
  end


end
