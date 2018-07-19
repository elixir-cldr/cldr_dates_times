defmodule Cldr.Calendar.ISOWeek do
  import Cldr.Calendar,
    only: [iso_days_from_date: 1, date_from_iso_days: 2, add: 2, day_of_year: 1]

  @doc """
  Returns the date of the first day of the first week of the year that includes
  the provided `date`.

  This conforms with the ISO standard definition of when the first week of the year
  begins:

  * If 1 January is on a Monday, Tuesday, Wednesday or Thursday, it is in week 01.

  * If 1 January is on a Friday, it is part of week 53 of the previous year;

  * If on a Saturday, it is part of week 52 (or 53 if the previous Gregorian year was a leap year)

  * If on a Sunday, it is part of week 52 of the previous year.

  IF a date if provided (as apposed to just a year) then we also need to make sure that the
  first week starts before the supplied date.
  """
  def first_week_of_year(%{year: year, calendar: calendar} = date) do
    estimate = first_week_of_year(year, calendar)

    if Date.compare(estimate, date) in [:lt, :eq] do
      estimate
    else
      first_week_of_year(year - 1, calendar)
    end
  end

  def first_week_of_year(year, calendar \\ Calendar.ISO) when is_integer(year) do
    new_year = %{year: year, month: 1, day: 1, calendar: calendar}
    {days, _fraction} = iso_days_from_date(new_year)

    case Date.day_of_week(new_year) do
      day when day in 1..4 ->
        date_from_iso_days({days - day + 1, {0, 1}}, calendar)

      day when day in 5..7 ->
        date_from_iso_days({days - day + 1 + 7, {0, 1}}, calendar)
    end
  end

  @doc """
  The last week of the ISO week-numbering year, i.e. the 52nd or 53rd one, is
  the week before week 01. This week’s properties are:

  * It has the year's last Thursday in it.

  * It is the last week with a majority (4 or more) of its days in December.

  * Its middle day, Thursday, falls in the ending year.

  * Its last day is the Sunday nearest to 31 December.

  * It has 28 December in it. Hence the earliest possible last week
  extends from Monday 22 December to Sunday 28 December, the latest possible
  last week extends from Monday 28 December to Sunday 3 January (next gregorian year).

  * If 31 December is on a Monday, Tuesday or Wednesday, it is in week 01 of the
  next year. If it is on a Thursday, it is in week 53 of the year just ending;
  if on a Friday it is in week 52 (or 53 if the year just ending is a leap year);
  if on a Saturday or Sunday, it is in week 52 of the year just ending.

  IF a date if provided (as apposed to just a year) then we also need to make sure that the
  last week accommodates the supplied date.
  """
  def last_week_of_year(%{year: year, calendar: calendar} = date) do
    estimate = last_week_of_year(year - 1, calendar)

    if Date.compare(add(estimate, 6), date) in [:gt, :eq] do
      estimate
    else
      last_week_of_year(year + 1, calendar)
    end
  end

  def last_week_of_year(year, calendar \\ Calendar.ISO) when is_integer(year) do
    end_of_year = %{year: year, month: 12, day: 31, calendar: calendar}
    {days, _fraction} = iso_days_from_date(end_of_year)

    case Date.day_of_week(end_of_year) do
      day when day in 1..3 ->
        date_from_iso_days({days - day - 6, {0, 1}}, calendar)

      day when day in 4..7 ->
        date_from_iso_days({days - day + 1, {0, 1}}, calendar)
    end
  end

  def first_day_of_year(year) do
    first_week_of_year(year)
  end

  def last_day_of_year(year) do
    year
    |> last_week_of_year
    |> add(6)
  end

  def year_number(%{year: year, month: _month, day: _day} =  date) do
    first_day = first_day_of_year(date)
    last_day = last_day_of_year(date)
    cond do
      first_day.month == 12 -> last_day.year
      last_day.month == 1 -> first_day.year
      true -> year
    end
  end

  def year_range(date) do
    %Date.Range{first: first_day_of_year(date), last: last_day_of_year(date)}
  end

  @doc """
  Returns the week of the year for the given date.

  Note that for some calendars (like `Calendar.ISO`), the first week
  of the year may not be the week that includes January 1st therefore
  for some dates near the start or end of the year, the week number
  may refer to a date in the following or previous Gregorian year.

  ## Examples

  """
  def week_of_year(%{year: year, month: _month, day: _day, calendar: _calendar} = date) do
    week = div(day_of_year(date) - Date.day_of_week(date) + 10, 7)

    cond do
      week >= 1 and week < 53 -> week
      week < 1 -> week_of_year(last_week_of_year(year - 1))
      week > week_of_year(last_week_of_year(year - 1)) -> 1
    end
  end

  @doc """
  Returns the number of weeks in a year

  ## Examples

      iex> Cldr.Calendar.weeks_in_year 2008
      52
      iex> Cldr.Calendar.weeks_in_year 2009
      53
      iex> Cldr.Calendar.weeks_in_year 2017
      52
  """
  def weeks_in_year(%{year: year}) do
    if leap_mod(year) == 4 or leap_mod(year - 1) == 3, do: 53, else: 52
  end

  def weeks_in_year(year, calendar \\ Calendar.ISO) do
    weeks_in_year(%{year: year, month: 1, day: 1, calendar: calendar})
  end

  defp leap_mod(year) do
    rem(year + div(year, 4) - div(year, 100) + div(year, 400), 7)
  end
end
