defmodule Cldr.DateTime.Relative do
  @moduledoc """
  Functions to support the string formatting of relative time/datetime numbers.

  This module provides formatting of numbers (as integers, floats, Dates or DateTimes)
  as "ago" or "in" with an appropriate time unit.  For example, "2 days ago" or
  "in 10 seconds"

  """

  @second 1
  @minute 60
  @hour 3600
  @day 86400
  @week 604_800
  @month 2_629_743.83
  @year 31_556_926

  @unit %{
    second: @second,
    minute: @minute,
    hour: @hour,
    day: @day,
    week: @week,
    month: @month,
    year: @year
  }

  @other_units [:mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]
  @unit_keys Map.keys(@unit) ++ @other_units
  @known_styles [:default, :narrow, :short]

  @doc """
  Returns a `{:ok, string}` representing a relative time (ago, in) for a given
  number, Date or Datetime.  Returns `{:error, reason}` when errors are detected.

  * `relative` is a number or Date/Datetime representing the time distance from `now` or from
    `options[:relative_to]`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a `Keyword` list of options which are:

  ## Options

  * `:locale` is the locale in which the binary is formatted.
    The default is `Cldr.get_locale/0`

  * `:format` is the format of the binary.  Format may be `:default`, `:narrow` or `:short`

  * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
    `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
    `:sun`, `:quarter`

  * `:relative_to` is the baseline Date or Datetime from which the difference from `relative` is
    calculated when `relative` is a Date or a DateTime. The default for a Date is `Date.utc_today`,
    for a DateTime it is `DateTime.utc_now`

  ### Notes

  When `options[:unit]` is not specified, `Cldr.DateTime.Relative.to_string/2` attempts to identify
  the appropriate unit based upon the magnitude of `relative`.  For example, given a parameter
  of less than `60`, then `to_string/2` will assume `:seconds` as the unit.  See `unit_from_relative_time/1`.

  ## Examples

      iex> Cldr.DateTime.Relative.to_string(-1, MyApp.Cldr)
      {:ok, "1 second ago"}

      iex> Cldr.DateTime.Relative.to_string(1, MyApp.Cldr)
      {:ok, "in 1 second"}

      iex> Cldr.DateTime.Relative.to_string(1, MyApp.Cldr, unit: :day)
      {:ok, "tomorrow"}

      iex> Cldr.DateTime.Relative.to_string(1, MyApp.Cldr, unit: :day, locale: "fr")
      {:ok, "demain"}

      iex> Cldr.DateTime.Relative.to_string(1, MyApp.Cldr, unit: :day, format: :narrow)
      {:ok, "tomorrow"}

      iex> Cldr.DateTime.Relative.to_string(1234, MyApp.Cldr, unit: :year)
      {:ok, "in 1,234 years"}

      iex> Cldr.DateTime.Relative.to_string(1234, MyApp.Cldr, unit: :year, locale: "fr")
      {:ok, "dans 1 234 ans"}

      iex> Cldr.DateTime.Relative.to_string(31, MyApp.Cldr)
      {:ok, "in 31 seconds"}

      iex> Cldr.DateTime.Relative.to_string(~D[2017-04-29], MyApp.Cldr, relative_to: ~D[2017-04-26])
      {:ok, "in 3 days"}

      iex> Cldr.DateTime.Relative.to_string(310, MyApp.Cldr, format: :short, locale: "fr")
      {:ok, "dans 5 min"}

      iex> Cldr.DateTime.Relative.to_string(310, MyApp.Cldr, format: :narrow, locale: "fr")
      {:ok, "+5 min"}

      iex> Cldr.DateTime.Relative.to_string 2, MyApp.Cldr, unit: :wed, format: :short, locale: "en"
      {:ok, "in 2 Wed."}

      iex> Cldr.DateTime.Relative.to_string 1, MyApp.Cldr, unit: :wed, format: :short
      {:ok, "next Wed."}

      iex> Cldr.DateTime.Relative.to_string -1, MyApp.Cldr, unit: :wed, format: :short
      {:ok, "last Wed."}

      iex> Cldr.DateTime.Relative.to_string -1, MyApp.Cldr, unit: :wed
      {:ok, "last Wednesday"}

      iex> Cldr.DateTime.Relative.to_string -1, MyApp.Cldr, unit: :quarter
      {:ok, "last quarter"}

      iex> Cldr.DateTime.Relative.to_string -1, MyApp.Cldr, unit: :mon, locale: "fr"
      {:ok, "lundi dernier"}

      iex> Cldr.DateTime.Relative.to_string(~D[2017-04-29], MyApp.Cldr, unit: :ziggeraut)
      {:error, {Cldr.UnknownTimeUnit,
       "Unknown time unit :ziggeraut.  Valid time units are [:day, :hour, :minute, :month, :second, :week, :year, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]"}}

  """

  @spec to_string(integer | float | Date.t() | DateTime.t(), Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(relative, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(relative, options, []) when is_list(options) do
    to_string(relative, Cldr.Date.default_backend(), options)
  end

  def to_string(relative, backend, options) do
    options = normalize_options(backend, options)
    locale = Keyword.get(options, :locale)
    {unit, options} = Keyword.pop(options, :unit)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, unit} <- validate_unit(unit),
         {:ok, _style} <- validate_style(options[:style] || options[:format]) do
      {relative, unit} = define_unit_and_relative_time(relative, unit, options[:relative_to])
      string = to_string(relative, unit, locale, backend, options)
      {:ok, string}
    end
  end

  defp normalize_options(backend, options) do
    {locale, _backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    style = options[:style] || options[:format] || :default

    options
    |> Keyword.put(:locale, locale)
    |> Keyword.put(:style, style)
    |> Keyword.delete(:format)
  end

  # No unit or relative_to is specified so we derive them
  defp define_unit_and_relative_time(relative, nil, nil) when is_number(relative) do
    unit = unit_from_relative_time(relative)
    relative = scale_relative(relative, unit)
    {relative, unit}
  end

  # Take two datetimes and calculate the seconds between them
  defp define_unit_and_relative_time(
         %{year: _, month: _, day: _, hour: _, minute: _, second: _, calendar: Calendar.ISO} =
           relative,
         unit,
         relative_to
       ) do
    now = (relative_to || DateTime.utc_now()) |> DateTime.to_unix()
    then = DateTime.to_unix(relative)
    relative_time = then - now
    unit = unit || unit_from_relative_time(relative_time)

    relative = scale_relative(relative_time, unit)
    {relative, unit}
  end

  # Take two dates and calculate the days between them
  defp define_unit_and_relative_time(
         %{year: _, month: _, day: _, calendar: Calendar.ISO} = relative,
         unit,
         relative_to
       ) do
    today =
      (relative_to || Date.utc_today())
      |> Date.to_erl()
      |> :calendar.date_to_gregorian_days()
      |> Kernel.*(@day)

    then =
      relative
      |> Date.to_erl()
      |> :calendar.date_to_gregorian_days()
      |> Kernel.*(@day)

    relative_time =
      then - today

    unit =
      unit || unit_from_relative_time(relative_time)

    relative = scale_relative(relative_time, unit)
    {relative, unit}
  end

  # Anything else just return the values
  defp define_unit_and_relative_time(relative_time, unit, _relative_to) do
    {relative_time, unit}
  end

  @doc """
  Returns a `{:ok, string}` representing a relative time (ago, in) for a given
  number, Date or Datetime or raises an exception on error.

  ## Arguments

  * `relative` is a number or Date/Datetime representing the time distance from `now` or from
    options[:relative_to].

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a `Keyword` list of options.

  ## Options

  * `:locale` is the locale in which the binary is formatted.
    The default is `Cldr.get_locale/0`

  * `:format` is the format of the binary.  Format may be `:default`, `:narrow` or `:short`.
    The default is `:default`

  * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
    `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
    `:sun`, `:quarter`

  * `:relative_to` is the baseline Date or Datetime from which the difference from `relative` is
    calculated when `relative` is a Date or a DateTime. The default for a Date is `Date.utc_today`,
    for a DateTime it is `DateTime.utc_now`

  See `to_string/3`

  """
  @spec to_string!(integer | float | Date.t() | DateTime.t(), Cldr.backend(), Keyword.t()) ::
          String.t()
  def to_string!(relative, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(relative, options, []) when is_list(options) do
    to_string!(relative, Cldr.Date.default_backend(), options)
  end

  def to_string!(relative, backend, options) do
    case to_string(relative, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @spec to_string(integer | float, atom(), Cldr.LanguageTag.t(), Cldr.backend(), Keyword.t()) ::
          String.t()

  defp to_string(relative, unit, locale, backend, options)

  # For the case when its relative by one unit, for example "tomorrow" or "yesterday"
  # or "last"
  defp to_string(relative, unit, locale, backend, options) when relative in -1..1 do
    style = options[:style] || options[:format]

    result =
      locale
      |> get_locale(backend)
      |> get_in([unit, style, :relative_ordinal])
      |> Enum.at(relative + 1)

    if is_nil(result), do: to_string(relative / 1, unit, locale, backend, options), else: result
  end

  # For the case when its more than one unit away. For example, "in 3 days"
  # or "2 days ago"
  defp to_string(relative, unit, locale, backend, options)
       when is_float(relative) or is_integer(relative) do
    direction = if relative > 0, do: :relative_future, else: :relative_past
    style = options[:style] || options[:format]

    rules =
      locale
      |> get_locale(backend)
      |> get_in([unit, style, direction])

    rule = Module.concat(backend, Number.Cardinal).pluralize(trunc(relative), locale, rules)

    relative
    |> abs
    |> Cldr.Number.to_string!(backend, locale: locale)
    |> Cldr.Substitution.substitute(rule)
    |> Enum.join()
  end

  # For all other cases
  # defp to_string(span, unit, locale, backend, options) do
  #   do_to_string(span, unit, locale, backend, options)
  # end
  #
  # defp do_to_string(seconds, unit, locale, backend, options) do
  #   seconds
  #   |> scale_relative(unit)
  #   |> to_string(unit, locale, backend, options)
  # end

  defp time_unit_error(unit) do
    {Cldr.UnknownTimeUnit,
     "Unknown time unit #{inspect(unit)}.  Valid time units are #{inspect(@unit_keys)}"}
  end

  defp style_error(style) do
    {Cldr.UnknownStyleError,
     "Unknown style #{inspect(style)}.  Valid styles are #{inspect(@known_styles)}"}
  end

  @doc """
  Returns an estimate of the appropriate time unit for an integer of a given
  magnitude of seconds.

  ## Examples

      iex> Cldr.DateTime.Relative.unit_from_relative_time(1234)
      :minute

      iex> Cldr.DateTime.Relative.unit_from_relative_time(12345)
      :hour

      iex> Cldr.DateTime.Relative.unit_from_relative_time(123456)
      :day

      iex> Cldr.DateTime.Relative.unit_from_relative_time(1234567)
      :week

      iex> Cldr.DateTime.Relative.unit_from_relative_time(12345678)
      :month

      iex> Cldr.DateTime.Relative.unit_from_relative_time(123456789)
      :year

  """
  def unit_from_relative_time(time) when is_number(time) do
    case abs(time) do
      i when i < @minute -> :second
      i when i < @hour -> :minute
      i when i < @day -> :hour
      i when i < @week -> :day
      i when i < @month -> :week
      i when i < @year -> :month
      _ -> :year
    end
  end

  def unit_from_relative_time(time) do
    time
  end

  @doc """
  Calculates the time span in the given `unit` from the time given in seconds.

  ## Examples

      iex> Cldr.DateTime.Relative.scale_relative(1234, :second)
      1234

      iex> Cldr.DateTime.Relative.scale_relative(1234, :minute)
      21

      iex> Cldr.DateTime.Relative.scale_relative(1234, :hour)
      0

  """
  def scale_relative(time, unit) when is_number(time) and is_atom(unit) do
    (time / @unit[unit])
    |> Float.round()
    |> trunc
  end

  @doc """
  Returns a list of the valid unit keys for `to_string/2`

  ## Example

      iex> Cldr.DateTime.Relative.known_units
      [:day, :hour, :minute, :month, :second, :week, :year, :mon, :tue, :wed, :thu,
       :fri, :sat, :sun, :quarter]

  """
  def known_units do
    @unit_keys
  end

  defp validate_unit(unit) when unit in @unit_keys or is_nil(unit) do
    {:ok, unit}
  end

  defp validate_unit(unit) do
    {:error, time_unit_error(unit)}
  end

  def known_styles do
    @known_styles
  end

  defp validate_style(style) when style in @known_styles do
    {:ok, style}
  end

  defp validate_style(style) do
    {:error, style_error(style)}
  end

  defp get_locale(locale, backend) do
    backend = Module.concat(backend, DateTime.Relative)
    backend.get_locale(locale)
  end
end
