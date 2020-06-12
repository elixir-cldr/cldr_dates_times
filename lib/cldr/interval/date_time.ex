defmodule Cldr.DateTime.Interval do
  @moduledoc """
  Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
  shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
  to take a start and end date, time or datetime plus a formatting pattern
  and use that information to produce a localized format.

  See `Cldr.Interval.to_string/3` and `Cldr.DateTime.Interval.to_string/3`

  """

  import Cldr.Date.Interval,
    only: [
      greatest_difference: 2
    ]

  import Cldr.Calendar,
    only: [
      naivedatetime: 0
    ]

  @default_format :medium
  @formats [:short, :medium, :long]

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string(%CalendarInterval{} = interval) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string(%CalendarInterval{} = interval, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend)
      when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(from, to, backend, options \\ [])

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, options, [])
      when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
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
         {:ok, format} <- validate_format(format),
         {:ok, calendar} <- Cldr.Calendar.validate_calendar(from.calendar),
         {:ok, greatest_difference} <- greatest_difference(from, to) do
      options = adjust_options(options, locale, format)
      format_date_time(from, to, locale, backend, calendar, greatest_difference, options)
    else
      {:error, :no_practical_difference} ->
        options = adjust_options(options, locale, format)
        Cldr.DateTime.to_string(from, backend, options)

      other ->
        other
    end
  end

  def to_string!(%Date.Range{} = range, backend) do
    to_string!(range, backend, [])
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string!(%CalendarInterval{} = range, backend) do
      to_string!(range, backend, [])
    end
  end

  def to_string!(%Date.Range{} = range, backend, options) do
    case to_string(range, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string!(%CalendarInterval{} = range, backend, options) do
      case to_string(range, backend, options) do
        {:ok, string} -> string
        {:error, {exception, reason}} -> raise exception, reason
      end
    end
  end

  def to_string!(from, to, backend, options \\ []) do
    case to_string(from, to, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp from_less_than_or_equal_to(%{time_zone: zone} = from, %{time_zone: zone} = to) do
    case DateTime.compare(from, to) do
      comp when comp in [:eq, :lt] -> {:ok, comp}
      _other -> {:error, Cldr.Date.Interval.datetime_order_error(from, to)}
    end
  end

  defp from_less_than_or_equal_to(%{time_zone: _zone1} = from, %{time_zone: _zone2} = to) do
    {:error, Cldr.Date.Interval.datetime_incompatible_timezone_error(from, to)}
  end

  defp from_less_than_or_equal_to(from, to) do
    case NaiveDateTime.compare(from, to) do
      comp when comp in [:eq, :lt] -> {:ok, comp}
      _other -> {:error, Cldr.Date.Interval.datetime_order_error(from, to)}
    end
  end

  @doc false
  def adjust_options(options, locale, format) do
    options
    |> Keyword.put(:locale, locale)
    |> Keyword.put(:format, format)
    |> Keyword.delete(:style)
  end

  defp format_date_time(from, to, locale, backend, calendar, difference, options) do
    backend_format = Module.concat(backend, DateTime.Format)
    {:ok, calendar} = Cldr.DateTime.type_from_calendar(calendar)
    fallback = backend_format.date_time_interval_fallback(locale, calendar)
    format = Keyword.fetch!(options, :format)

    [from_format, to_format] = extract_format(format)
    from_options = Keyword.put(options, :format, from_format)
    to_options = Keyword.put(options, :format, to_format)

    do_format_date_time(from, to, backend, format, difference, from_options, to_options, fallback)
  end

  # The difference is only in the time part
  defp do_format_date_time(from, to, backend, format, difference, from_opts, to_opts, fallback)
       when difference in [:H, :m] do
    with {:ok, from_string} <- Cldr.DateTime.to_string(from, backend, from_opts),
         {:ok, to_string} <- Cldr.Time.to_string(to, backend, to_opts) do
      {:ok, combine_result(from_string, to_string, format, fallback)}
    end
  end

  # The difference is in the date part
  # Format each datetime separately and join with
  # the interval fallback format
  defp do_format_date_time(from, to, backend, format, difference, from_opts, to_opts, fallback)
       when difference in [:y, :M, :d] do
    with {:ok, from_string} <- Cldr.DateTime.to_string(from, backend, from_opts),
         {:ok, to_string} <- Cldr.DateTime.to_string(to, backend, to_opts) do
      {:ok, combine_result(from_string, to_string, format, fallback)}
    end
  end

  defp combine_result(left, right, format, _fallback) when is_list(format) do
    left <> right
  end

  defp combine_result(left, right, format, fallback) when is_atom(format) do
    [left, right]
    |> Cldr.Substitution.substitute(fallback)
    |> Enum.join()
  end

  defp extract_format(format) when is_atom(format) do
    [format, format]
  end

  defp extract_format([from_format, to_format]) do
    [from_format, to_format]
  end

  # Using standard format terms like :short, :medium, :long
  defp validate_format(format) when format in @formats do
    {:ok, format}
  end

  # Direct specification of a format as a string
  @doc false
  defp validate_format(format) when is_binary(format) do
    Cldr.DateTime.Format.split_interval(format)
  end

  @doc false
  def format_error(format) do
    {
      Cldr.DateTime.UnresolvedFormat,
      "The interval format #{inspect(format)} is invalid. " <>
        "Valid formats are #{inspect(@formats)} or an interval format string.}"
    }
  end
end
