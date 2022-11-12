defmodule Cldr.Time.Interval do
  @moduledoc """
  Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
  shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
  to take a start and end date, time or datetime plus a formatting pattern
  and use that information to produce a localized format.

  See `Cldr.Interval.to_string/3` and `Cldr.Time.Interval.to_string/3`

  """

  alias Cldr.DateTime.Format

  import Cldr.Date.Interval,
    only: [
      format_error: 2,
      style_error: 1
    ]

  import Cldr.Calendar,
    only: [
      time: 0
    ]

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

  @doc false
  def to_string(unquote(time()) = from, unquote(time()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(time()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(time()) = from, nil = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  @doc false
  def to_string(unquote(time()) = from, unquote(time()) = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(time()) = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(time()) = from, nil = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  @doc false
  def to_string(unquote(time()) = from, unquote(time()) = to, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(nil = from, unquote(time()) = to, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(time()) = from, nil = to, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  @doc """
  Returns a string representing the formatted
  interval formed by two times.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.time` type.

  * `to` is any map that conforms to the
    `Calendar.time` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  Either `from` or `to` may also be `nil` in which case the
  interval is formatted as an open interval with the non-nil
  side formatted as a standalone time.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:time`, `:zone`,
    and `:flex`. The default is `:time`.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  ## Returns

  * `{:ok, string}` or

  * `{:error, {exception, reason}}`

  ## Notes

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configured locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    time is formatted instead of an interval

  ## Examples

      iex> Cldr.Time.Interval.to_string ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :short
      {:ok, "10 – 10"}

      iex> Cldr.Time.Interval.to_string ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :medium
      {:ok, "10:00 – 10:03 AM"}

      iex> Cldr.Time.Interval.to_string ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :long
      {:ok, "10:00 – 10:03 AM"}

      iex> Cldr.Time.Interval.to_string ~T[10:00:00], ~T[10:03:00], MyApp.Cldr,
      ...> format: :long, style: :flex
      {:ok, "10:00 – 10:03 in the morning"}

      iex> Cldr.Time.Interval.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
      ...> MyApp.Cldr, format: :long, style: :flex
      {:ok, "12:00 – 10:00 in the morning"}

      iex> Cldr.Time.Interval.to_string ~U[2020-01-01 00:00:00.0Z], nil, MyApp.Cldr,
      ...> format: :long, style: :flex
      {:ok, "12:00:00 AM UTC –"}

      iex> Cldr.Time.Interval.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
      ...> MyApp.Cldr, format: :long, style: :zone
      {:ok, "12:00 – 10:00 AM Etc/UTC"}

      iex> Cldr.Time.Interval.to_string ~T[10:00:00], ~T[10:03:00], MyApp.Cldr,
      ...> format: :long, style: :flex, locale: "th"
      {:ok, "10:00 – 10:03 ในตอนเช้า"}

  """
  @spec to_string(Calendar.time() | nil, Calendar.time() | nil, Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

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
    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)

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

  # Open ended intervals use the `date_time_interval_fallback/0` format
  def to_string(nil, unquote(time()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)

    with {:ok, formatted} <- Cldr.Time.to_string(to, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale)
      result =
        ["", formatted]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_leading()

      {:ok, result}
    end
  end

  def to_string(unquote(time()) = from, nil, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)

    with {:ok, formatted} <- Cldr.Time.to_string(from, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale)
      result =
        [formatted, ""]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_trailing()

      {:ok, result}
    end
  end

  @doc false
  def to_string!(unquote(time()) = from, unquote(time()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string!(from, to, backend, locale: locale)
  end

  @doc """
  Returns a string representing the formatted
  interval formed by two times.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.time` type.

  * `to` is any map that conforms to the
    `Calendar.time` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:time`, `:zone`,
    and `:flex`. The default is `:time`.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  ## Returns

  * `string` or

  * raises an exception

  ## Notes

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configured locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    time is formatted instead of an interval

  ## Examples

      iex> Cldr.Time.Interval.to_string! ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :short
      "10 – 10"

      iex> Cldr.Time.Interval.to_string! ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :medium
      "10:00 – 10:03 AM"

      iex> Cldr.Time.Interval.to_string! ~T[10:00:00], ~T[10:03:00], MyApp.Cldr, format: :long
      "10:00 – 10:03 AM"

      iex> Cldr.Time.Interval.to_string! ~T[10:00:00], ~T[10:03:00], MyApp.Cldr,
      ...> format: :long, style: :flex
      "10:00 – 10:03 in the morning"

      iex> Cldr.Time.Interval.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
      ...> MyApp.Cldr, format: :long, style: :flex
      "12:00 – 10:00 in the morning"

      iex> Cldr.Time.Interval.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
      ...> MyApp.Cldr, format: :long, style: :zone
      "12:00 – 10:00 AM Etc/UTC"

      iex> Cldr.Time.Interval.to_string! ~T[10:00:00], ~T[10:03:00], MyApp.Cldr,
      ...> format: :long, style: :flex, locale: "th"
      "10:00 – 10:03 ในตอนเช้า"

  """
  def to_string!(from, to, backend, options \\ []) do
    case to_string(from, to, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Returns the format code representing the date or
  time unit that is the greatest difference between
  two times.

  Only differences in hours or minutes are considered.

  ## Arguments

  * `from` is any `t:Time.t/0`

  * `to` is any `t:Time.t/0`

  ## Returns

  * `{:ok, format_code}` where `format_code` is one of

    * `:H` meaning that the greatest difference is in the hour
    * `:m` meaning that the greatest difference is in the minute

  * `{:error, :no_practical_difference}`

  ## Example

      iex> Cldr.Time.Interval.greatest_difference ~T[10:11:00], ~T[10:12:00]
      {:ok, :m}

      iex> Cldr.Time.Interval.greatest_difference ~T[10:11:00], ~T[10:11:00]
      {:error, :no_practical_difference}

  """
  def greatest_difference(from, to) do
    Cldr.Date.Interval.greatest_difference(from, to)
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
      greatest_difference_format(from, to, format, greatest_difference)
    end
  end

  defp greatest_difference_format(_from, _to, format, _) when is_binary(format) do
    {:ok, format}
  end

  defp greatest_difference_format(%{hour: from}, %{hour: to}, format, :H)
       when from < 12 and to >= 12 do
    case Map.get(format, :b) || Map.get(format, :a) || Map.get(format, :h) do
      nil -> {:error, format_error(format, format)}
      success -> {:ok, success}
    end
  end

  defp greatest_difference_format(_from, _to, format, :H) do
    case Map.fetch(format, :h) do
      :error -> {:error, format_error(format, format)}
      success -> success
    end
  end

  defp greatest_difference_format(from, to, format, :m = difference) do
    case Map.fetch(format, difference) do
      :error -> greatest_difference_format(from, to, format, :H)
      success -> success
    end
  end

  defp greatest_difference_format(_from, _to, _format, _difference) do
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
    IO.inspect(format_key, label: "format key 2")

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
