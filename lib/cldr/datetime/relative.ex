defmodule Cldr.DateTime.Relative do
  @moduledoc """
  Functions to support the string formatting of relative time/datetime numbers.

  This module provides formatting of numbers (as integers, floats, Dates or DateTimes)
  as "ago" or "in" with an appropriate time unit.  For example, "2 days ago" or
  "in 10 seconds"

  """
  import Cldr.DateTime.Formatter, only: :macros

  @second 1
  @minute 60
  @hour 3600
  @day 86400
  @week 604_800
  @month 2_629_743.83
  @year 31_556_926

  @unit_steps %{
    second: @second,
    minute: @minute,
    hour: @hour,
    day: @day,
    week: @week,
    month: @month,
    year: @year
  }

  @other_units [:mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]
  @unit_keys Enum.sort(Map.keys(@unit_steps) ++ @other_units)
  @known_styles [:default, :narrow, :short]

  @doc """
  Returns a `{:ok, string}` representing a relative time (ago, in) for a given
  number, Date or Datetime.  Returns `{:error, reason}` when errors are detected.

  * `relative` is an integer or `t:DateTime.t/0`, `t:Date.t/0` or `t:Time.t/0` representing the
    time distance from `now` or from `options[:relative_to]`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a `t:Keyword.t/0` list of options.

  ## Options

  * `:locale` is the locale in which the binary is formatted.
    The default is `Cldr.get_locale/0`

  * `:format` is the format of the binary.  Format may be `:default`, `:narrow` or `:short`.

  * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
    `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
    `:sun`, `:quarter`. If no `:unit` is specified, one will be derived using the
    `:derive_unit_from` option.

  * `:relative_to` is the baseline `t:Date/0` or `t:Datetime.t/0` from which the difference
    from `relative` is calculated when `relative` is a Date or a DateTime. The default for
    a `t:Date.t/0` is `Date.utc_today/0`, for a `t:DateTime.t/0` it is `DateTime.utc_now/0`.

  * `:derive_unit_from` is used to derive the most appropriate time unit if none is provided.
    THere are two ways to specify `:derive_unit_from`.

    * The first option is a map. The map is required to have the keys `:second`, `:minute`, `:hour`,
      `:day`, `:week`, `:month`, and `:year` with the values being the number of seconds below
      which the key defines the time unit difference. This is the default and its value is:

      #{inspect(@unit_steps)}

    * The second option is to specify a function reference. The function must take four
      arguments as described below.

  ### The :derive_unit_from` *map*

  * Any `:derive_unit_from` map is first merged into the default map. This means that developers
    can use the default values and override only specific entries by providing a sparse map.

  * Any entry in the `:derive_unit_from` map that has a value of `nil` is ignored. This has the
    result that any key set to `nil` will never be represented in the output.

  * Any entry in the `:derive_unit_from` map that has the value `:infinity` will always be the
    largest time unit used to represent the relative time.

  ### The :derive_unit_from *function*

  * The function must take four arguments:
    * `relative`, being the first argument to `to_string/3`.
    * `relative_to` being the value of option `:relative_to` or its default value.
    * `time_difference` being the difference in seconds between `relative`
      and `relative_to`.
    * `unit` being the requested time unit which may be `nil`. If `nil` then
      the time unit must be derived and the `time_difference` scaled to that
      time unit. If specified then the `time_difference` must be scaled to
      that time unit.

  * The function must return a tuple of the form `{relative, unit}` where
    `relative` is an integer value and `unit` is the appropriate time unit atom.

  * See the `Cldr.DateTime.Relative.derive_unit_from/4` function for an example.

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
      {:error, {Cldr.DateTime.UnknownTimeUnit,
       "Unknown time unit :ziggeraut.  Valid time units are [:day, :fri, :hour, :minute, :mon, :month, :quarter, :sat, :second, :sun, :thu, :tue, :wed, :week, :year]"}}

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
    {derive_unit_from, options} = Keyword.pop(options, :derive_unit_from, @unit_steps)
    relative_to = Keyword.get_lazy(options, :relative_to, &DateTime.utc_now/0)
    style = options[:style] || options[:format]

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, unit} <- validate_unit(unit),
         {:ok, _style} <- validate_style(style),
         {:ok, time_difference} <- time_difference(relative, relative_to) do
      {relative, unit} = define_unit(relative, relative_to, time_difference, unit, derive_unit_from)
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

  # If an integer (not a date or datetime) is given, use that value directly
  defp time_difference(relative, _relative_to) when is_integer(relative) do
    {:ok, relative}
  end

  # If realtive is a datetime then relative_to must be too
  defp time_difference(relative, relative_to) when is_date_time(relative) do
    seconds = DateTime.diff(relative, relative_to)
    {:ok, seconds}
  end

  defp time_difference(relative, relative_to) when is_date(relative) do
    seconds = Date.diff(relative, relative_to) * @day
    {:ok, seconds}
  end

  defp time_difference(relative, relative_to) when is_time(relative) do
    seconds = Time.diff(relative, relative_to)
    {:ok, seconds}
  end

  # No unit specified so we derive it
  defp define_unit(_relative, _relative_to, time_difference, nil = unit, derive_unit_from)
       when is_map(derive_unit_from) do
    derive_unit_from = Map.merge(@unit_steps, derive_unit_from)
    unit = unit_from_relative_time(time_difference, unit, derive_unit_from)
    relative = scale_relative(time_difference, unit, derive_unit_from)
    {relative, unit}
  end

  # Use the unit and difference as supplied
  defp define_unit(relative, _relative_to, _time_difference, unit, _derive_unit_from)
       when is_integer(relative) do
    {relative, unit}
  end

  # It's a calculated difference, it needs scaling
  defp define_unit(_relative, _relative_to, time_difference, unit, derive_unit_from)
       when is_map(derive_unit_from) do
    derive_unit_from = Map.merge(@unit_steps, derive_unit_from)
    relative = scale_relative(time_difference, unit, derive_unit_from)
    {relative, unit}
  end

  # derive_unit_from is a function that is required to return a
  # `{relative, unit}` tuple where `relative` is an integer number to
  # be presented as a `unit`
  defp define_unit(relative, relative_to, time_difference, unit, derive_unit_from)
       when is_function(derive_unit_from, 4) do
    derive_unit_from.(relative, relative_to, time_difference, unit)
  end

  @doc """
  Returns a string representing a relative time (ago, in) for a given
  number, Date or Datetime or raises an exception on error.

  ## Arguments

  * `relative` is an integer or `t:DateTime.t/0`, `t:Date.t/0` or `t:Time.t/0` representing the
    time distance from `now` or from `options[:relative_to]`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a `t:Keyword.t/0` list of options.

  ## Options

  * `:locale` is the locale in which the binary is formatted.
    The default is `Cldr.get_locale/0`.

  * `:format` is the format of the binary.  Format may be `:default`, `:narrow` or `:short`.
    The default is `:default`.

  * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
    `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
    `:sun`, `:quarter`. If no `:unit` is specified, one will be derived using the
    `:derive_unit_from` option.

  * `:relative_to` is the baseline `t:Date/0` or `t:Datetime.t/0` from which the difference
    from `relative` is calculated when `relative` is a Date or a DateTime. The default for
    a `t:Date.t/0` is `Date.utc_today/0`, for a `t:DateTime.t/0` it is `DateTime.utc_now/0`.

  * `:derive_unit_from` is used to derive the most appropriate time unit if none is provided.
    THere are two ways to specify `:derive_unit_from`.

    * The first option is a map. The map is required to have the keys `:second`, `:minute`, `:hour`,
      `:day`, `:week`, `:month`, and `:year` with the values being the number of seconds below
      which the key defines the time unit difference. This is the default and its value is:

      #{inspect(@unit_steps)}

    * The second option is to specify a function reference. The function must take four
      arguments as described below.

  ### The :derive_unit_from` *map*

  * Any `:derive_unit_from` map is first merged into the default map. This means that developers
    can use the default values and override only specific entries by providing a sparse map.

  * Any entry in the `:derive_unit_from` map that has a value of `nil` is ignored. This has the
    result that any key set to `nil` will never be represented in the output.

  * Any entry in the `:derive_unit_from` map that has the value `:infinity` will always be the
    largest time unit used to represent the relative time.

  ### The :derive_unit_from *function*

  * The function must take four arguments:
    * `relative`, being the first argument to `to_string/3`.
    * `relative_to` being the value of option `:relative_to` or its default value.
    * `time_difference` being the difference in seconds between `relative`
      and `relative_to`.
    * `unit` being the requested time unit which may be `nil`. If `nil` then
      the time unit must be derived and the `time_difference` scaled to that
      time unit. If specified then the `time_difference` must be scaled to
      that time unit.

  * The function must return a tuple of the form `{relative, unit}` where
    `relative` is an integer value and `unit` is the appropriate time unit atom.

  * See the `Cldr.DateTime.Relative.derive_unit_from/4` function for an example.

  See `to_string/3` for example usage.

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
    |> abs()
    |> Cldr.Number.to_string!(backend, locale: locale)
    |> Cldr.Substitution.substitute(rule)
    |> Enum.join()
  end

  defp time_unit_error(unit) do
    {Cldr.DateTime.UnknownTimeUnit,
     "Unknown time unit #{inspect(unit)}.  Valid time units are #{inspect(@unit_keys)}"}
  end

  defp style_error(style) do
    {Cldr.UnknownStyleError,
     "Unknown style #{inspect(style)}.  Valid styles are #{inspect(@known_styles)}"}
  end

  @doc """
  An example implementation of a function to derive an appropriate
  time unit for a relative time.

  ### Arguments

  * `relative`, the first argument provided to `to_string/3`.

  * `relative_to` the value of option `:relative_to` provided to `to_string/3`
    or its default value.

  * `time_difference` is the difference in seconds between `relative`
    and `relative_to`.

  * `unit` being the requested time unit which may be `nil`. If `nil` then
    the time unit must be derived and the `time_difference` scaled to that
    time unit. If specified then the `time_difference` must be scaled to
    that time unit.

  ### Returns

  * `{relative, unit}` where `relative` is the integer value of the
    derived and scaled time unit. `unit` is the derived or given time unit.

  ### Notes

  * In [this implementation](https://github.com/elixir-cldr/cldr_dates_times/blob/main/lib/cldr/datetime/relative.ex#L390-L467)
    the time difference is used to derive seconds, minutes, hours, days and weeks.
    The `:month` and `:year` fields of the the `relative` struct are used to derive months
    and years.

  """
  def derive_unit_from(relative, relative_to, time_difference, nil) do
    cond do
      time_difference < 90 ->
        derive_unit_from(relative, relative_to, time_difference, :second)

      time_difference < 90 * 60 ->
        derive_unit_from(relative, relative_to, time_difference, :minute)

      time_difference < 60 * 60 * 36 ->
        derive_unit_from(relative, relative_to, time_difference, :hour)

      time_difference < 60 * 60 * 24 * 13 ->
        derive_unit_from(relative, relative_to, time_difference, :day)

      time_difference < 60 * 60 * 24 * 10 * 7 ->
        derive_unit_from(relative, relative_to, time_difference, :week)

      relative.year == relative_to.year ->
        derive_unit_from(relative, relative_to, time_difference, :month)

      true ->
        derive_unit_from(relative, relative_to, time_difference, :year)
    end
  end

  def derive_unit_from(_relative, _relative_to, time_difference, :second) do
    {time_difference, :second}
  end

  def derive_unit_from(_relative, _relative_to, time_difference, :minute) do
    {div(time_difference, 90), :minute}
  end

  def derive_unit_from(_relative, _relative_to, time_difference, :hour) do
    {div(time_difference, 60 * 60), :hour}
  end

  def derive_unit_from(_relative, _relative_to, time_difference, :day) do
    {div(time_difference, 60 * 60 * 24), :day}
  end

  def derive_unit_from(_relative, _relative_to, time_difference, :week) do
    {div(time_difference, 60 * 60 * 24 * 10), :week}
  end

  def derive_unit_from(relative, relative_to, _time_difference, :month) do
    {relative.month - relative_to.month, :month}
  end

  def derive_unit_from(relative, relative_to, _time_difference, :year) do
    {relative.year - relative_to.year, :year}
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
  def unit_from_relative_time(time_difference, unit \\ nil, derive_unit_from \\ @unit_steps)

  def unit_from_relative_time(time_difference, nil, derive_unit_from)
      when is_number(time_difference) and is_map(derive_unit_from) do
    time_difference = abs(time_difference)

    cond do
      unit?(time_difference, derive_unit_from[:minute]) -> :second
      unit?(time_difference, derive_unit_from[:hour]) -> :minute
      unit?(time_difference, derive_unit_from[:day]) -> :hour
      unit?(time_difference, derive_unit_from[:week]) -> :day
      unit?(time_difference, derive_unit_from[:month]) -> :week
      unit?(time_difference, derive_unit_from[:year]) -> :month
      true -> :year
    end
  end

  def unit_from_relative_time(_time_difference, unit, _derive_unit_from) do
    unit
  end

  defp unit?(_time_difference, nil) do
    false
  end

  defp unit?(_time_difference, :infinity) do
    true
  end

  defp unit?(time_difference, unit_time) do
    time_difference < unit_time
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
  def scale_relative(time_difference, unit, derive_unit_from \\ @unit_steps)
      when is_number(time_difference) and is_atom(unit) and is_map(derive_unit_from) do
    (time_difference / derive_unit_from[unit])
    |> Float.round()
    |> trunc
  end

  @doc """
  Returns a list of the valid unit keys for `to_string/2`

  ## Example

      iex> Cldr.DateTime.Relative.known_units()
      [:day, :fri, :hour, :minute, :mon, :month, :quarter, :sat, :second,
      :sun, :thu, :tue, :wed, :week, :year]

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
