defmodule Cldr.Calendar do
  alias Cldr.Calendar.Conversion
  alias Cldr.Locale
  require Cldr

  @default_calendar :gregorian

  # Default territory is "World"
  @default_territory :"001"

  @week_data Cldr.Config.week_data
  def week_data do
    @week_data
  end

  def minumim_days_in_week_1(territory \\ @default_territory) do
    get_in(week_data(), [:min_days, territory])
  end

  @calendar_data Cldr.Config.calendar_data
  def calendars do
    @calendar_data
  end

  def available_calendars do
    calendars()
    |> Map.keys
  end

  def era_number_from_date(date, calendar) do
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

  def date_from_iso_days(days, calendar) do
    {year, month, day, _, _, _, _} = calendar.naive_datetime_from_iso_days(days)
    %{year: year, month: month, day: day, calendar: calendar}
  end

  def iso_days_from_date(%{year: _, month: _, day: _, calendar: _} = date) do
    date
    |> naive_datetime_from_date
    |> iso_days_from_datetime
  end

  def naive_datetime_from_date(%{year: year, month: month, day: day, calendar: calendar}) do
    {:ok, naive_datetime} = NaiveDateTime.new(year, month, day, 0, 0, 0, {0, 6}, calendar)
    naive_datetime
  end

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

  def day_of_year(%{year: year, calendar: calendar} = date) do
    {days, _fraction} = iso_days_from_date(date)
    {new_year, _fraction} = iso_days_from_date(%{year: year, month: 1, day: 1, calendar: calendar})
    days - new_year
  end

  def day_of_week(%{year: year, month: month, day: day, calendar: calendar}) do
    calendar.day_of_week(year, month, day)
  end

  @doc """
  Returns the date that is the first day of the `n`th week of
  the given `date`
  """
  def nth_week_of_year(%{year: year, calendar: calendar}, n) do
    nth_week_of_year(year, n, calendar)
  end

  def nth_week_of_year(year, n, calendar \\ Calendar.ISO) do
    first_week = calendar.first_week_of_year(year)
    {first_week_starts, _fraction} = iso_days_from_date(first_week)

    date_from_iso_days({first_week_starts + ((n - 1) * 7), {0, 1}}, calendar)
  end

  def previous_day(%{calendar: _calendar} = date) do
    add(date, -1)
  end

  def next_day(%{calendar: _calendar} = date) do
    add(date, 1)
  end

  def add(%{calendar: calendar} = date, n) do
    {days, fraction} = iso_days_from_date(date)
    date_from_iso_days({days + n, fraction}, calendar)
  end

  def sub(%{calendar: _calendar} = date, n) do
    add(date, n * -1)
  end

  @doc """
  Returns the first day of the month.

  Note that whilst this is trivial for an ISO/Gregorian calendar it may
  well be quite different for other types of calendars
  """
  def first_day_of_month(%{year: _year, month: _month, calendar: Calendar.ISO} = date) do
    date
    |> Map.put(:day, 1)
  end

  def year(%{calendar: calendar} = date) do
    date
    |> calendar.last_week_of_year
    |> Map.get(:year)
  end

  def iso_days_to_float({days, {numerator, denominator}}) do
    days + (numerator / denominator)
  end

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

  def known_calendars do
    @known_calendars
  end

  #
  # Data storage functions
  #

  for locale <- Cldr.known_locales() do
    date_data =
      locale
      |> Cldr.Config.get_locale
      |> Map.get(:dates)

    calendars =
      date_data
      |> Map.get(:calendars)
      |> Map.take(@known_calendars)
      |> Map.keys

    for calendar <- calendars do
      def era(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :eras])))
      end

      def period(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :day_periods])))
      end

      def quarter(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :quarters])))
      end

      def month(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :months])))
      end

      def day(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :days])))
      end
    end

    def era(unquote(locale), calendar), do: {:error, calendar_error(calendar)}
    def period(unquote(locale), calendar), do: {:error, calendar_error(calendar)}
    def quarter(unquote(locale), calendar), do: {:error, calendar_error(calendar)}
    def month(unquote(locale), calendar), do: {:error, calendar_error(calendar)}
    def day(unquote(locale), calendar), do: {:error, calendar_error(calendar)}
  end

  def era(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def period(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def quarter(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def month(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def day(locale, _calendar), do: {:error, Locale.locale_error(locale)}
end

