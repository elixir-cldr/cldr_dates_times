defmodule Cldr.Date.Interval do
  alias Cldr.DateTime.Format

  # Date styles not defined
  # by a grouping but can still
  # be used directly

  # :y_m_ed
  # :m_ed
  # :d
  # :m
  # :y

  @doc false
  @style_map %{
    # Can be used with any
    # date
    date: %{
      short: :y_md,
      medium: :y_mm_md,
      long: :y_mmm_ed
    },

    # Can be used when the year
    # is the same with different
    # months and days
    month_and_day: %{
      short: :md,
      medium: :mm_md,
      long: :mmm_ed
    },

    # Can be used when the year
    # is the same and the coverage
    # is full months
    month: %{
      short: :m,
      medium: :mmm,
      long: :mmm
    },

    # Can be used when different
    # years and the coverage is
    # full months
    year_and_month: %{
      short: :y_m,
      medium: :y_mmm,
      long: :y_mmmm
    }
  }

  @styles Map.keys(@style_map)
  @formats Map.keys(@style_map.date)

  @default_format :medium
  @default_style :date

  def styles do
    @style_map
  end

  def to_string(%Date.Range{first: first, last: last}, backend) do
    to_string(first, last, backend, [])
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{} = interval, backend) do
      to_string(interval, backend, [])
    end
  end

  def to_string(%Date.Range{first: first, last: last}, backend, options) do
    to_string(first, last, backend, options)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:year, :month, :day] do
      to_string(from, to, backend, options)
    end

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:hour, :minute] do
      from = %{from | second: 0, microsecond: {0, 6}}
      to = %{to | second: 0, microsecond: {0, 6}}
      Cldr.DateTime.Interval.to_string(from, to, backend, options)
    end
  end

  def to_string(from, to, backend, options \\ [])

  def to_string(%{calendar: Calendar.ISO} = from, %{calendar: Calendar.ISO} = to, backend, options) do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(%{calendar: calendar} = from, %{calendar: calendar} = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    formatter = Module.concat(backend, DateTime.Formatter)
    format = Keyword.get(options, :format, @default_format)

    with {:ok, backend} <- Cldr.validate_backend(backend),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, calendar} <- Cldr.Calendar.validate_calendar(from.calendar),
         {:ok, formats} <- Format.interval_formats(locale, calendar.cldr_calendar_type, backend),
         {:ok, [left, right]} <- resolve_format(from, to, formats, options),
         {:ok, left_format} <- formatter.format(from, left, locale, options),
         {:ok, right_format} <- formatter.format(to, right, locale, options) do
      {:ok, left_format <> right_format}
    else
      {:error, :no_practical_difference} ->
        options =
          options
          |> Keyword.put(:locale, locale)
          |> Keyword.put(:format, format)
          |> Keyword.delete(:style)

        Cldr.Date.to_string(from, backend, options)

      other ->
        other
    end
  end

  def resolve_format(from, to, formats, options) do
    format = Keyword.get(options, :format, @default_format)
    style = Keyword.get(options, :style, @default_style)

    with {:ok, style} <- validate_style(style),
         {:ok, format} <- validate_format(formats, style, format),
         {:ok, greatest_difference} <- greatest_difference(from, to) do
      greatest_difference_format(format, greatest_difference)
    end
  end

  defp greatest_difference_format(format, _) when is_binary(format) do
    {:ok, format}
  end

  defp greatest_difference_format(format, _) when is_list(format) do
    {:ok, format}
  end

  defp greatest_difference_format(format, :y = difference) do
    case Map.fetch(format, difference) do
      :error -> {:error, format_error(format, difference)}
      success -> success
    end
  end

  defp greatest_difference_format(format, :M) do
    case Map.fetch(format, :m) do
      :error -> greatest_difference_format(format, :y)
      success -> success
    end
  end

  defp greatest_difference_format(format, :d = difference) do
    case Map.fetch(format, difference) do
      :error -> greatest_difference_format(format, :M)
      success -> success
    end
  end

  defp greatest_difference_format(_format, _difference) do
    {:error, :no_practical_difference}
  end

  defp validate_style(style) when style in @styles, do: {:ok, style}
  defp validate_style(style), do: {:error, style_error(style)}

  # Using standard format terms like :short, :medium, :long
  defp validate_format(formats, style, format) when format in @formats do
    format_key =
      styles()
      |> Map.fetch!(style)
      |> Map.fetch!(format)

    Map.fetch(formats, format_key)
  end

  # Direct specification of a format
  @doc false
  defp validate_format(formats, _style, format_key) when is_atom(format_key) do
    case Map.fetch(formats, format_key) do
      :error -> {:error, format_error(formats, format_key)}
      success -> success
    end
  end

  # Direct specification of a format as a string
  @doc false
  defp validate_format(_formats, _style, format) when is_binary(format) do
    Cldr.DateTime.Format.split_interval(format)
  end

  @doc false
  def style_error(style) do
    {
      Cldr.DateTime.InvalidStyle,
      "The interval style #{inspect(style)} is invalid. " <>
        "Valid styles are #{inspect(@styles)}."
    }
  end

  @doc false
  def format_error(_formats, format) do
    {
      Cldr.DateTime.UnresolvedFormat,
      "The interval format #{inspect(format)} is invalid. " <>
        "Valid formats are #{inspect(@formats)} or an interval format string."
    }
  end

  @doc false

  # Returns the map key for interval formatting
  # based upon the greatest difference between
  # two dates/times represented as a duration.

  # Microseconds and seconds are ignored since they have
  # no format placeholder in interval formats.
  import Cldr.Calendar, only: [date: 0, naivedatetime: 0, datetime: 0, time: 0]

  def greatest_difference(unquote(datetime()) = from, unquote(datetime()) = to) do
    cond do
      from.year != to.year -> {:ok, :y}
      from.month != to.month -> {:ok, :M}
      from.day != to.day -> {:ok, :d}
      from.hour != to.hour -> {:ok, :H}
      from.minute != to.minute -> {:ok, :m}
      true -> {:error, :no_practical_difference}
    end
  end

  def greatest_difference(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to) do
    cond do
      from.year != to.year -> {:ok, :y}
      from.month != to.month -> {:ok, :M}
      from.day != to.day -> {:ok, :d}
      from.hour != to.hour -> {:ok, :H}
      from.minute != to.minute -> {:ok, :m}
      true -> {:error, :no_practical_difference}
    end
  end

  def greatest_difference(unquote(date()) = from, unquote(date()) = to) do
    cond do
      from.year != to.year -> {:ok, :y}
      from.month != to.month -> {:ok, :M}
      from.day != to.day -> {:ok, :d}
      true -> {:error, :no_practical_difference}
    end
  end

  def greatest_difference(unquote(time()) = from, unquote(time()) = to) do
    cond do
      from.hour != to.hour -> {:ok, :H}
      from.minute != to.minute -> {:ok, :m}
      true -> {:error, :no_practical_difference}
    end
  end
end
