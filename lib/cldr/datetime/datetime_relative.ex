defmodule Cldr.DateTime.Relative do
  @moduledoc """
  Functions to support the string formatting of relative time/datetime numbers.

  This module provides formatting of numbers (as integers, floats, Dates or DateTimes)
  as "ago" or "in" with an appropriate time unit.  For example, "2 days ago" or
  "in 10 seconds"
  """
  alias Cldr.LanguageTag

  @second 1
  @minute 60
  @hour   3600
  @day    86400
  @week   604800
  @month  2629743.83
  @year   31556926

  @unit %{
    second: @second,
    minute: @minute,
    hour:   @hour,
    day:    @day,
    week:   @week,
    month:  @month,
    year:   @year
  }

  @other_units [:mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]
  @unit_keys Map.keys(@unit) ++ @other_units

  @doc """
  Returns a `{:ok, string}` representing a relative time (ago, in) for a given
  number, Date or Datetime.  Returns `{:error, reason}` when errors are detected.

  * `relative` is a number or Date/Datetime representing the time distance from `now` or from
  options[:relative_to]

  * `options` is a `Keyword` list of options which are:

    * `:locale` is the locale in which the binary is formatted.  The default is `Cldr.get_current_locale/0`
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

      iex> Cldr.DateTime.Relative.to_string(-1)
      {:ok, "1 second ago"}

      iex> Cldr.DateTime.Relative.to_string(1)
      {:ok, "in 1 second"}

      iex> Cldr.DateTime.Relative.to_string(1, unit: :day)
      {:ok, "tomorrow"}

      iex> Cldr.DateTime.Relative.to_string(1, unit: :day, locale: "fr")
      {:ok, "demain"}

      iex> Cldr.DateTime.Relative.to_string(1, unit: :day, format: :narrow)
      {:ok, "tomorrow"}

      iex> Cldr.DateTime.Relative.to_string(1234, unit: :year)
      {:ok, "in 1,234 years"}

      iex> Cldr.DateTime.Relative.to_string(1234, unit: :year, locale: "fr")
      {:ok, "dans 1 234 ans"}

      iex> Cldr.DateTime.Relative.to_string(31)
      {:ok, "in 31 seconds"}

      iex> Cldr.DateTime.Relative.to_string(~D[2017-04-29], relative_to: ~D[2017-04-26])
      {:ok, "in 3 days"}

      iex> Cldr.DateTime.Relative.to_string(310, format: :short, locale: "fr")
      {:ok, "dans 5 min"}

      iex> Cldr.DateTime.Relative.to_string(310, format: :narrow, locale: "fr")
      {:ok, "+5 min"}

      iex> Cldr.DateTime.Relative.to_string 2, unit: :wed, format: :short, locale: "en"
      {:ok, "in 2 Wed."}

      iex> Cldr.DateTime.Relative.to_string 1, unit: :wed, format: :short
      {:ok, "next Wed."}

      iex> Cldr.DateTime.Relative.to_string -1, unit: :wed, format: :short
      {:ok, "last Wed."}

      iex> Cldr.DateTime.Relative.to_string -1, unit: :wed
      {:ok, "last Wednesday"}

      iex> Cldr.DateTime.Relative.to_string -1, unit: :quarter
      {:ok, "last quarter"}

      iex> Cldr.DateTime.Relative.to_string -1, unit: :mon, locale: "fr"
      {:ok, "lundi dernier"}

      iex> Cldr.DateTime.Relative.to_string(~D[2017-04-29], unit: :ziggeraut)
      {:error, {Cldr.UnknownTimeUnit,
       "Unknown time unit :ziggeraut.  Valid time units are [:day, :hour, :minute, :month, :second, :week, :year, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]"}}

  """
  @spec to_string(integer | float | Date.t | DateTime.t, []) :: binary
  def to_string(relative, options \\ []) do
    options = Keyword.merge(default_options(), options)
    locale = Keyword.get(options, :locale)
    {unit, options} = Keyword.pop(options, :unit)

    with \
      {:ok, locale} <- Cldr.validate_locale(locale),
      {:ok, unit} <- validate_unit(unit),
      {relative, unit} = define_unit_and_relative_time(relative, unit, options[:relative_to]),
      string <- to_string(relative, unit, locale, options)
    do
      {:ok, string}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp default_options do
    [locale: Cldr.get_current_locale(), format: :default]
  end

  defp define_unit_and_relative_time(relative, nil, nil) when is_number(relative) do
    unit = unit_from_relative_time(relative)
    relative = scale_relative(relative, unit)
    {relative, unit}
  end

  defp define_unit_and_relative_time(%{year: _, month: _, day: _, hour: _, minute: _, second: _,
                   calendar: Calendar.ISO} = relative, unit, relative_to) do
    now = (relative_to || DateTime.utc_now) |> DateTime.to_unix
    then = DateTime.to_unix(relative)
    relative_time = then - now
    define_unit_and_relative_time(relative_time, unit, nil)
  end

  defp define_unit_and_relative_time(%{year: _, month: _, day: _, calendar: Calendar.ISO} = relative, unit, relative_to) do
    today =
      (relative_to || Date.utc_today)
      |> Date.to_erl
      |> :calendar.date_to_gregorian_days
      |> Kernel.*(@day)

    then =
      relative
      |> Date.to_erl
      |> :calendar.date_to_gregorian_days
      |> Kernel.*(@day)

    relative_time = then - today
    define_unit_and_relative_time(relative_time, unit, nil)
  end

  defp define_unit_and_relative_time(relative_time, unit, _relative_to) do
    {relative_time, unit}
  end

  @doc """
  Returns a `{:ok, string}` representing a relative time (ago, in) for a given
  number, Date or Datetime or raises an exception on error.

  ## Options

  * `relative` is a number or Date/Datetime representing the time distance from `now` or from
  options[:relative_to]

  * `options` is a `Keyword` list of options which are:

    * `:locale` is the locale in which the binary is formatted.  The default is `Cldr.get_current_locale/0`
    * `:format` is the format of the binary.  Format may be `:default`, `:narrow` or `:short`
    * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
    `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
    `:sun`, `:quarter`
    * `:relative_to` is the baseline Date or Datetime from which the difference from `relative` is
    calculated when `relative` is a Date or a DateTime. The default for a Date is `Date.utc_today`,
    for a DateTime it is `DateTime.utc_now`

  See `to_string/2`
  """
  def to_string!(relative, options \\ []) do
    case to_string(relative, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp to_string(relative, unit, locale, options)
  when is_integer(relative) and relative in [-1, 0, +1] do
    result =
      locale
      |> get_locale()
      |> get_in([unit, options[:format], :relative_ordinal])
      |> Enum.at(relative + 1)

    if is_nil(result), do: to_string(relative / 1, unit, locale, options), else: result
  end

  defp to_string(relative, unit, locale, options) when is_number(relative)  do
    direction = if relative > 0, do: :relative_future, else: :relative_past

    rules =
      locale
      |> get_locale()
      |> get_in([unit, options[:format], direction])

    rule = Cldr.Number.Cardinal.pluralize(trunc(relative), locale, rules)

    relative
    |> abs
    |> Cldr.Number.to_string!(locale: locale)
    |> Cldr.Substitution.substitute(rule)
    |> Enum.join
  end

  defp to_string(span, unit, locale, options) do
    do_to_string(span, unit, locale, options)
  end

  defp do_to_string(seconds, unit, locale, options) do
    seconds
    |> scale_relative(unit)
    |> to_string(unit, locale, options)
  end

  defp time_unit_error(unit) do
    {Cldr.UnknownTimeUnit, "Unknown time unit #{inspect unit}.  Valid time units are #{inspect @unit_keys}"}
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
      i when i < @minute  -> :second
      i when i < @hour    -> :minute
      i when i < @day     -> :hour
      i when i < @week    -> :day
      i when i < @month   -> :week
      i when i < @year    -> :month
      _                   -> :year
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
    |> Float.round
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

  def validate_unit(unit) when unit in @unit_keys or is_nil(unit) do
    {:ok, unit}
  end

  def validate_unit(unit) do
    {:error, time_unit_error(unit)}
  end

  for locale_name <- Cldr.known_locale_names() do
    locale_data =
      locale_name
      |> Cldr.Config.get_locale
      |> Map.get(:date_fields)
      |> Map.take(@unit_keys)

    defp get_locale(%LanguageTag{cldr_locale_name: unquote(locale_name)}), do: unquote(Macro.escape(locale_data))
  end
end
