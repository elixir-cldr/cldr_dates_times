defmodule Cldr.Calendar do
  @moduledoc """
  Calendar support functions for formatting dates, times and datetimes.

  `Cldr` defines formats for several calendars, the names of which
  are returned by `Cldr.Calendar.known_calendars/0`.

  Currently this implementation only supports the `:gregorian`
  calendar which aligns with the proleptic Gregorian calendar
  defined by Elixir, `Calendar.ISO`.

  This module will be extacted in the future to become part of
  a separate calendrical module.
  """
  alias Cldr.LanguageTag
  alias Cldr.Calendar.Conversion
  alias Cldr.Calendar.ISOWeek
  alias Cldr.Locale
  require Cldr

  @doc """
  Returns the default CLDR calendar name.

  Note this is not the same as the default calendar
  `Calendar.ISO` supported by Elixir.

  ## Example

      iex> Cldr.Calendar.default_calendar
      :gregorian

  """
  @default_calendar :gregorian
  def default_calendar do
    @default_calendar
  end

  # Default territory is "World"
  @default_region Cldr.default_region |> String.to_atom

  @doc """
  Returns the CLDR data that defines the structure
  of a week in different locales.

  ## Example

      Cldr.Calendar.week_data
      %{first_day: %{IN: "sun", SM: "mon", MN: "mon", MZ: "sun", CR: "mon", AT: "mon",
          LA: "sun", EE: "mon", NL: "mon", PT: "mon", PH: "sun", BG: "mon", LT: "mon",
          ES: "mon", OM: "sat", SY: "sat", US: "sun", EC: "mon", SG: "sun", DM: "sun",
          AR: "sun", MK: "mon", YE: "sun", KW: "sat", GB: "mon",
          "GB-alt-variant": "sun", AD: "mon", UZ: "mon", KG: "mon", CZ: "mon",
          FI: "mon", RO: "mon", TR: "mon", AI: "mon", MM: "sun", AS: "sun", BS: "sun",
          IT: "mon", MX: "sun", BR: "sun", ID: "sun", NZ: "sun", GP: "mon", BE: "mon",
          CO: "sun", GR: "mon", NP: "sun", ME: "mon", MO: "sun", ...},
        min_days: %{SM: 4, SJ: 4, AT: 4, EE: 4, NL: 4, PT: 4, BG: 4, LT: 4, ES: 4,
          US: 1, GI: 4, GB: 4, AD: 4, CZ: 4, FI: 4, IT: 4, GP: 4, JE: 4, BE: 4, GR: 4,
          "001": 1, VI: 1, RE: 4, SE: 4, GU: 1, IS: 4, AN: 4, IM: 4, GG: 4, CH: 4,
          FO: 4, UM: 1, SK: 4, AX: 4, LU: 4, FR: 4, IE: 4, HU: 4, FJ: 4, MC: 4, GF: 4,
          NO: 4, DK: 4, DE: 4, LI: 4, PL: 4, VA: 4, MQ: 4}, weekend_end: nil,
        weekend_start: nil}

  """
  @week_data Cldr.Config.week_data
  def week_data do
    @week_data
  end

  @doc """
  Returns the first day of a week for a locale as an ordinal number
  in then range one to seven with one representing Monday and seven
  representing Sunday.

  ## Example

      iex> Cldr.Calendar.first_day_of_week Cldr.Locale.new("en")
      7

      iex> Cldr.Calendar.first_day_of_week Cldr.Locale.new("en-GB")
      1

  """
  def first_day_of_week(locale) do
    (get_in(week_data(), [:first_day, region_from_locale(locale)]) ||
     get_in(week_data(), [:first_day, @default_region]))
    |> day_ordinal
  end

  @doc """
  Returns the minimum days required in a week for it
  to be considered week one of a year.

  ## Examples

      iex> Cldr.Calendar.minumim_days_in_week_one :US
      1

      iex> Cldr.Calendar.minumim_days_in_week_one :FR
      4

  """
  def minumim_days_in_week_one(region \\ @default_region) do
    get_in(week_data(), [:min_days, region])
  end

  @doc """
  Returns the calendar type and calendar era definitions
  for the calendars in CLDR.

  ## Example

      Cldr.Calendar.calendars
      %{buddhist: %{calendar_system: "solar", eras: [{0, %{start: -198326}}]},
        chinese: %{calendar_system: "lunisolar", eras: [{0, %{start: -963144}}]},
        coptic: %{calendar_system: "other",
          eras: [{0, %{end: 103604}}, {1, %{start: 103605}}]},
        dangi: %{calendar_system: "lunisolar", eras: [{0, %{start: -852110}}]},
        ethiopic: %{calendar_system: "other",
          eras: [{0, %{end: 2797}}, {1, %{start: 2798}}]},
        ethiopic_amete_alem: %{eras: [{0, %{end: -2006036}}]},
        gregorian: %{calendar_system: "solar",
          eras: [{0, %{end: 0}}, {1, %{start: 1}}]}, ...

  """
  @calendar_data Cldr.Config.calendar_data
  def calendars do
    @calendar_data
  end

  @doc """
  Returns the names of the calendars defined in CLDR.

  ## Example

      iex> Cldr.Calendar.available_calendars
      [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :gregorian, :hebrew, :indian, :islamic, :islamic_civil, :islamic_rgsa,
       :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]

  """
  def available_calendars do
    calendars()
    |> Map.keys
  end

  @doc """
  Returns the era number for a given date and calendar

  * `date` is a `Date` or any struct with the fields `:year`,
  `:month`, `:day` and `:calendar`

  * `calendar` is any calendar returned by `Cldr.Calendar.known_calendars/0`

  ## Example

      iex> Cldr.Calendar.era_number_from_date ~D[2017-09-03], :gregorian
      1

      iex> Cldr.Calendar.era_number_from_date ~D[0000-09-03], :gregorian
      0

      iex> Cldr.Calendar.era_number_from_date ~D[1700-09-03], :japanese
      208

  """
  def era_number_from_date(date, calendar \\ Cldr.Calendar.default_calendar) do
    date
    |> Conversion.to_iso_days
    |> era_from_iso_days(calendar)
  end

  @doc """
  Returns the era number for a given rata die.

  The era number is an index into Cldr list of
  eras for a given calendar which is primarily
  for the use of `Cldr.Date.to_string/2` when
  processing the format symbol `G`. For further
  information see `Cldr.DateTime.Formatter.era/4`.
  """
  def era_from_iso_days(iso_days, calendar)

  for {calendar, content} <- @calendar_data do
    Enum.each content[:eras], fn
      {era, %{start: start, end: finish}} ->
        def era_from_iso_days(iso_days, unquote(calendar))
          when iso_days in unquote(start)..unquote(finish), do: unquote(era)
      {era, %{start: start}} ->
        def era_from_iso_days(iso_days, unquote(calendar))
          when iso_days >= unquote(start), do: unquote(era)
      {era, %{end: finish}} ->
        def era_from_iso_days(iso_days, unquote(calendar))
          when iso_days <= unquote(finish), do: unquote(era)
    end
  end

  @doc """
  Returns a date struct for a given iso days
  """
  def date_from_iso_days(days, calendar) do
    {year, month, day, _, _, _, _} = calendar.naive_datetime_from_iso_days(days)
    %{year: year, month: month, day: day, calendar: calendar}
  end

  @doc """
  Returns iso days for a given date
  """
  def iso_days_from_date(%{year: _, month: _, day: _, calendar: _} = date) do
    date
    |> naive_datetime_from_date
    |> iso_days_from_datetime
  end

  @doc """
  Converts a date to a naive datetime
  """
  def naive_datetime_from_date(%{year: year, month: month, day: day, calendar: calendar}) do
    {:ok, naive_datetime} = NaiveDateTime.new(year, month, day, 0, 0, 0, {0, 6}, calendar)
    naive_datetime
  end

  @doc """
  Converts a datetime to iso days
  """
  def iso_days_from_datetime(%NaiveDateTime{year: year, month: month, day: day,
                hour: hour, minute: minute, second: second, microsecond: microsecond,
                calendar: calendar}) do
    calendar.naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond)
  end

  def iso_days_from_datetime(%DateTime{year: year, month: month, day: day,
                hour: hour, minute: minute, second: second, microsecond: microsecond,
                calendar: calendar, zone_abbr: "UTC", time_zone: "Etc/UTC"}) do
    calendar.naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond)
  end

  @doc """
  Returns the ordinal day of the year for a given
  date.

  ## Example

      iex> Cldr.Calendar.day_of_year ~D[2017-01-01]
      1

      iex> Cldr.Calendar.day_of_year ~D[2017-09-03]
      246

      iex> Cldr.Calendar.day_of_year ~D[2017-12-31]
      365

  """
  def day_of_year(%{year: year, month: _month, day: _day, calendar: calendar} = date) do
    {days, _fraction} = iso_days_from_date(date)
    {new_year, _fraction} = iso_days_from_date(%{year: year, month: 1, day: 1, calendar: calendar})
    days - new_year + 1
  end

  @doc """
  Returns the day of the week for a date where
  the first day is Monday and the result is in
  the range `1` (for Monday) to `7` (for Sunday)

  ## Examples

      iex> Cldr.Calendar.day_of_week ~D[2017-09-03]
      7

      iex> Cldr.Calendar.day_of_week ~D[2017-09-01]
      5

  """
  def day_of_week(%{year: year, month: month, day: day, calendar: calendar}) do
    calendar.day_of_week(year, month, day)
  end

  @doc """
  Returns the date that is the first day of the `n`th week of
  the year that containts the supplied `date`.

  * `date` is a `Date` or any other struct that contains the
  keys `:year`, `:month`, `;day` and `:calendar`

  * `n` is the week number

  *NOTE* The first week is defined according to the week
  definition of the ISO Week calendar.

  ## Example

      iex> Cldr.Calendar.nth_week_of_year ~D[2017-01-04], 1
      %{calendar: Calendar.ISO, day: 2, month: 1, year: 2017}

  """
  def nth_week_of_year(%{year: _year, calendar: Calendar.ISO} = date, n) do
    date
    |> ISOWeek.first_day_of_year
    |> add(7 * (n - 1))
  end

  def nth_week_of_year(%{year: _year, calendar: calendar} = date, n) do
    date
    |> calendar.first_day_of_year
    |> add(7 * (n - 1))
  end

  def nth_week_of_year(year, n, Calendar.ISO) do
    year
    |> ISOWeek.first_day_of_year
    |> add(7 * (n - 1))
  end

  @doc """
  Returns the date of the previous day to the
  provided date.

  ## Example

      iex> Cldr.Calendar.previous_day %{calendar: Calendar.ISO, day: 2, month: 1, year: 2017}
      %{calendar: Calendar.ISO, day: 1, month: 1, year: 2017}

      iex> Cldr.Calendar.previous_day %{calendar: Calendar.ISO, day: 1, month: 3, year: 2017}
      %{calendar: Calendar.ISO, day: 28, month: 2, year: 2017}

      iex> Cldr.Calendar.previous_day %{calendar: Calendar.ISO, day: 1, month: 3, year: 2016}
      %{calendar: Calendar.ISO, day: 29, month: 2, year: 2016}

  """
  def previous_day(%{calendar: _calendar} = date) do
    add(date, -1)
  end

  @doc """
  Returns the date of the next day to the
  provided date.

  ## Examples

      iex> Cldr.Calendar.next_day %{calendar: Calendar.ISO, day: 2, month: 1, year: 2017}
      %{calendar: Calendar.ISO, day: 3, month: 1, year: 2017}

      iex> Cldr.Calendar.next_day %{calendar: Calendar.ISO, day: 28, month: 2, year: 2017}
      %{calendar: Calendar.ISO, day: 1, month: 3, year: 2017}

      iex> Cldr.Calendar.next_day %{calendar: Calendar.ISO, day: 28, month: 2, year: 2016}
      %{calendar: Calendar.ISO, day: 29, month: 2, year: 2016}

  """
  def next_day(%{calendar: _calendar} = date) do
    add(date, 1)
  end

  @doc """
  Returns the date `n` days after the provided
  data.

  ## Examples

  """
  def add(%{calendar: calendar} = date, n) do
    {days, fraction} = iso_days_from_date(date)
    date_from_iso_days({days + n, fraction}, calendar)
  end

  @doc """
  Returns the date `n` days after the provided
  data.

  ## Example

      iex> Cldr.Calendar.add %{calendar: Calendar.ISO, day: 1, month: 3, year: 2017}, 3
      %{calendar: Calendar.ISO, day: 4, month: 3, year: 2017}

  """
  def sub(%{calendar: _calendar} = date, n) do
    add(date, n * -1)
  end

  defp region_from_locale(locale) do
    try do
      String.to_existing_atom(locale.region)
    catch
      _, _ -> @default_region
    end
  end

  # erlang/elixir standard is that Monday -> 1
  def day_key(1), do: :mon
  def day_key(2), do: :tue
  def day_key(3), do: :wed
  def day_key(4), do: :thu
  def day_key(5), do: :fri
  def day_key(6), do: :sat
  def day_key(7), do: :sun

  def day_ordinal("mon"), do: 1
  def day_ordinal("tue"), do: 2
  def day_ordinal("wed"), do: 3
  def day_ordinal("thu"), do: 4
  def day_ordinal("fri"), do: 5
  def day_ordinal("sat"), do: 6
  def day_ordinal("sun"), do: 7
  def day_ordinal(_), do: nil

  @doc """
  Returns the first day of the month.

  *Note* that whilst this is trivial for an ISO/Gregorian calendar it may
  well be quite different for other types of calendars
  """
  def first_day_of_month(%{year: _year, month: _month, calendar: Calendar.ISO} = date) do
    date
    |> Map.put(:day, 1)
  end

  @doc """
  Returns a `Date.Rage` with the first date as the
  first day of the year and the last day as the last
  day of the year

  ## Example

  """
  def year(%{calendar: Calendar.ISO} = date) do
    %Date.Range{first: ISOWeek.first_day_of_year(date), last: ISOWeek.last_day_of_year(date)}
  end

  def year(%{calendar: calendar} = date) do
    %Date.Range{first: calendar.first_day_of_year(date), last: calendar.last_day_of_year(date)}
  end

  @doc false
  def iso_days_to_float({days, {numerator, denominator}}) do
    days + (numerator / denominator)
  end

  @doc false
  def calendar_error(calendar_name) do
    {Cldr.UnknownCalendarError, "The calendar #{inspect calendar_name} is not known."}
  end

  @configured_calendars Application.get_env(:ex_cldr, :calendars) || [@default_calendar]
  @known_calendars "root"
      |> Cldr.Config.get_locale
      |> Map.get(:dates)
      |> Map.get(:calendars)
      |> Map.keys
      |> MapSet.new
      |> MapSet.intersection(MapSet.new(@configured_calendars))
      |> MapSet.to_list

  @doc """
  Returns a list of the known calendars in CLDR

  ## Example

      iex> Cldr.Calendar.known_calendars
      [:gregorian]

  """
  def known_calendars do
    @known_calendars
  end

  #
  # Data storage functions
  #
  @doc false
  def era(locale, calendar)

  @doc false
  def period(locale, calendar)

  @doc false
  def quarter(locale, calendar)

  @doc false
  def month(locale, calendar)

  @doc false
  def day(locale, calendar)

  for locale_name <- Cldr.known_locales() do
    date_data =
      locale_name
      |> Cldr.Config.get_locale
      |> Map.get(:dates)

    calendars =
      date_data
      |> Map.get(:calendars)
      |> Map.take(@known_calendars)
      |> Map.keys

    for calendar <- calendars do
      def era(%LanguageTag{cldr_locale_name: unquote(locale_name)}, unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :eras])))
      end

      def period(%LanguageTag{cldr_locale_name: unquote(locale_name)}, unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :day_periods])))
      end

      def quarter(%LanguageTag{cldr_locale_name: unquote(locale_name)}, unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :quarters])))
      end

      def month(%LanguageTag{cldr_locale_name: unquote(locale_name)}, unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :months])))
      end

      def day(%LanguageTag{cldr_locale_name: unquote(locale_name)}, unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :days])))
      end
    end

    def era(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
    def period(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
    def quarter(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
    def month(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
    def day(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
  end

  def era(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def period(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def quarter(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def month(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def day(locale, _calendar), do: {:error, Locale.locale_error(locale)}
end

