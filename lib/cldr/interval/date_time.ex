defmodule Cldr.DateTime.Interval do
  alias Cldr.DateTime.Format

  def to_string(%Date.Range{first: first, last: last}, backend, options) do
    to_string(first, last, backend, options)
  end

  def to_string(%{calendar: Calendar.ISO} = from, %{calendar: Calendar.ISO} = to, backend, options) do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}
    to_string(from, to, backend, options)
  end

  def to_string(%{calendar: calendar} = from, %{calendar: calendar} = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    formatter = Module.concat(backend, DateTime.Formatter)

    with {:ok, duration} <- Cldr.Calendar.Duration.new(from, to),
         {:ok, backend} <- Cldr.validate_backend(backend),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, calendar} <- Cldr.validate_calendar(from.calendar),
         {:ok, formats} = Format.interval_formats(locale, calendar.cldr_calendar_type, backend) do

      format = Keyword.get(options, :format)
      format = Map.fetch!(formats, format)

      greatest_difference = greatest_difference(duration)
      [left, right] = Map.get(format, greatest_difference)

      {:ok, left_format} = formatter.format(from, left, locale, options)
      {:ok, right_format} = formatter.format(to, right, locale, options)

      {:ok, left_format <> right_format}
    end
  end

  @doc false
  @default_difference :s

  # Returns the map key for interval formatting
  # based upon the greatest difference between
  # two dates/times represented as a duration

  def greatest_difference(%Cldr.Calendar.Duration{} = duration) do
    cond do
      duration.year != 0 -> :y
      duration.month != 0 -> :m
      duration.day != 0 -> :d
      duration.hour != 0 -> :h
      duration.minute != 0 -> :m
      duration.second != 0 -> :s
      true -> @default_difference
    end
  end
end
