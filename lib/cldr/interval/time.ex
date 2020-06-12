defmodule Cldr.Time.Interval do
  alias Cldr.DateTime.Format

  import Cldr.Date.Interval,
    only: [
      format_error: 2,
      style_error: 1,
      greatest_difference: 2
    ]

  import Cldr.Calendar, only: [time: 0]

  # Time styles not defined
  # by a grouping but can still
  # be used directly

  @doc false
  @style_map %{
    # Can be used with any
    # time
    time: %{
      short: :h,
      medium: :hm,
      long: :hm
    },

    # Includes the timezone
    zone: %{
      short: :hv,
      medium: :hmv,
      long: :hmv
    },

    # Includes flex times
    # annotation like
    # ".. in the evening"
    flex: %{
      short: :bh,
      medium: :bhm,
      long: :bhm
    }
  }

  @styles Map.keys(@style_map)
  @formats Map.keys(@style_map.time)

  @default_format :medium
  @default_style :time

  def styles do
    @style_map
  end

  def to_string(from, to, backend, options \\ [])

  def to_string(%{calendar: calendar} = from, %{calendar: calendar} = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(time()) = from, unquote(time()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    formatter = Module.concat(backend, DateTime.Formatter)
    format = Keyword.get(options, :format, @default_format)

    number_system =
      Keyword.get(
        options,
        :number_system,
        Cldr.Number.System.number_system_from_locale(locale, backend)
      )

    options =
      options
      |> Keyword.put(:locale, locale)
      |> Keyword.put(:nunber_system, number_system)

    with {:ok, _} <- from_less_than_or_equal_to(from, to),
         {:ok, backend} <- Cldr.validate_backend(backend),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         {:ok, calendar} <- Cldr.Calendar.validate_calendar(from.calendar),
         {:ok, formats} <- Format.interval_formats(locale, calendar.cldr_calendar_type, backend),
         {:ok, [left, right]} <- resolve_format(from, to, formats, options),
         {:ok, left_format} <- formatter.format(from, left, locale, options),
         {:ok, right_format} <- formatter.format(to, right, locale, options) do
      {:ok, left_format <> right_format}
    else
      {:error, :no_practical_difference} ->
        options = Cldr.DateTime.Interval.adjust_options(options, locale, format)
        Cldr.Time.to_string(from, backend, options)

      other ->
        other
    end
  end

  def to_string!(from, to, backend, options \\ []) do
    case to_string(from, to, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp from_less_than_or_equal_to(from, to) do
    case Time.compare(from, to) do
      comp when comp in [:eq, :lt] -> {:ok, comp}
      _other -> {:error, Cldr.Date.Interval.datetime_order_error(from, to)}
    end
  end

  defp resolve_format(from, to, formats, options) do
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

  defp greatest_difference_format(format, :H) do
    case Map.fetch(format, :h) do
      :error -> {:error, format_error(format, format)}
      success -> success
    end
  end

  defp greatest_difference_format(format, :m = difference) do
    case Map.fetch(format, difference) do
      :error -> greatest_difference_format(format, :H)
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
end
