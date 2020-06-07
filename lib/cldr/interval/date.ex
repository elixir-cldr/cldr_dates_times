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

  def styles do
    @style_map
  end

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
         {:ok, calendar} <- Cldr.Calendar.validate_calendar(from.calendar),
         {:ok, formats} <- Format.interval_formats(locale, calendar.cldr_calendar_type, backend),
         {:ok, [left, right]} <- resolve_format(duration, formats, options),
         {:ok, left_format} <- formatter.format(from, left, locale, options),
         {:ok, right_format} <- formatter.format(to, right, locale, options) do

      {:ok, left_format <> right_format}
    end
  end

  @default_format :medium
  @default_style :date

  def resolve_format(duration, formats, options) do
    format = Keyword.get(options, :format, @default_format)
    style = Keyword.get(options, :style, @default_style)

    with {:ok, style} <- validate_style(style),
         {:ok, format} <- validate_format(formats, style, format),
         {:ok, greatest_difference} = greatest_difference(duration) do
      greatest_difference_format(format, greatest_difference)
    end
  end

  defp greatest_difference_format(format, difference) do
    case Map.fetch(format, difference) do
      :error ->  {:error, format_error(format, format)}
      success -> success
    end
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
  defp validate_format(formats, _style, format_key) when is_atom(format_key) do
    case Map.fetch(formats, format_key) do
      :error -> {:error, format_error(formats, format_key)}
      success -> success
    end
  end

  # Direct specification of a format as a string
  defp validate_format(_formats, _style, format) when is_binary(format) do
    Cldr.DateTime.Format.split_interval(format)
  end

  defp style_error(style) do
     {
       Cldr.DateTime.InvalidStyle,
       "The interval style #{inspect style} is invalid. " <>
       "Valid styles are #{inspect @styles}"
     }
  end

  defp format_error(formats, format) do
     {
       Cldr.DateTime.UnresolvedFormat,
       "The interval format #{inspect format} is invalid. " <>
       "Valid formats are #{inspect(@formats ++ Map.keys(formats))}"
     }
  end

  @doc false

  # Returns the map key for interval formatting
  # based upon the greatest difference between
  # two dates/times represented as a duration.

  # Microseconds are ignored since they have
  # no format placeholder in interval formats.

  def greatest_difference(%Cldr.Calendar.Duration{} = duration) do
    cond do
      duration.year != 0 -> {:ok, :y}
      duration.month != 0 -> {:ok, :M}
      duration.day != 0 -> {:ok, :d}
      duration.hour != 0 -> {:ok, :H}
      duration.minute != 0 -> {:ok, :m}
      duration.second != 0 -> {:ok, :s}
      true -> {:error, :no_practical_difference}
    end
  end
end
