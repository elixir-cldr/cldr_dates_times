defmodule Cldr.Date.Interval do
  @moduledoc """
  Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
  shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
  to take a start and end date, time or datetime plus a formatting pattern
  and use that information to produce a localized format.

  See `Cldr.Interval.to_string/3` and `Cldr.Date.Interval.to_string/3`

  """
  alias Cldr.DateTime.Format
  import Cldr.Calendar, only: [date: 0]

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

  @doc false
  def to_string(%Date.Range{first: first, last: last}) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(first, last, backend, locale: locale)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string(%CalendarInterval{} = interval) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(date()) = from, unquote(date()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(date()) = to) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(date()) = from, nil = to) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  @doc false
  def to_string(%Date.Range{first: first, last: last}, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(first, last, backend, locale: locale)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string(%CalendarInterval{} = interval, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(date()) = from, unquote(date()) = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(date()) = to, backend) when is_atom(backend) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(date()) = from, nil = to, backend) when is_atom(backend) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  @doc """
  Returns a `Date.Range` or `CalendarInterval` as
  a localised string.

  ## Arguments

  * `range` is either a `Date.Range.t` returned from `Date.range/2`
    or a `CalendarInterval.t`

  * `backend` is any module that includes `use Cldr` and
    is therefore an `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:date`, `:month_and_day`, `:month`
    and `:year_and_month`. The default is `:date`.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:number_system` a number system into which the formatted date digits should
    be transliterated

  ## Returns

  * `{:ok, string}` or

  * `{:error, {exception, reason}}`

  ## Notes

  * `CalendarInterval` support requires adding the
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see the `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ## Examples

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-12-31]), MyApp.Cldr
      {:ok, "Jan 1 – Dec 31, 2020"}

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr
      {:ok, "Jan 1 – 12, 2020"}

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long
      {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-12-01]), MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      {:ok, "January – December 2020"}

      iex> use CalendarInterval
      iex> Cldr.Date.Interval.to_string ~I"2020-01/12", MyApp.Cldr
      {:ok, "Jan 1 – Dec 31, 2020"}

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :short
      {:ok, "1/1/2020 – 1/12/2020"}

      iex> Cldr.Date.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long, locale: "fr"
      {:ok, "mer. 1 – dim. 12 janv. 2020"}

  """
  @spec to_string(Cldr.Interval.range(), Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

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

  @doc """
  Returns a localised string representing the formatted
  interval formed by two dates.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.date` type.

  * `to` is any map that conforms to the
    `Calendar.date` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore an `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  Either `from` or `to` may also be `nil` in which case the
  interval is formatted as an open interval with the non-nil
  side formatted as a standalone date.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:date`, `:month_and_day`, `:month`
    and `:year_and_month`. The default is `:date`.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  ## Returns

  * `{:ok, string}` or

  * `{:error, {exception, reason}}`

  ## Notes

  * For more information on interval format string
    see the `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ## Examples

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-12-31], MyApp.Cldr
      {:ok, "Jan 1 – Dec 31, 2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr
      {:ok, "Jan 1 – 12, 2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long
      {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-12-01], MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      {:ok, "January – December 2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :short
      {:ok, "1/1/2020 – 1/12/2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], nil, MyApp.Cldr,
      ...> format: :short
      {:ok, "1/1/20 –"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long, locale: "fr"
      {:ok, "mer. 1 – dim. 12 janv. 2020"}

      iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long, locale: "th", number_system: :thai
      {:ok, "พ. ๑ ม.ค. – อา. ๑๒ ม.ค. ๒๐๒๐"}

  """
  @spec to_string(Calendar.date() | nil, Calendar.date() | nil, Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_string(from, to, backend, options \\ [])

  def to_string(unquote(date()) = from, unquote(date()) = to, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(nil = from, unquote(date()) = to, options, []) when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(date()) = from, nil = to, options, []) when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(date()) = from, unquote(date()) = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(nil = from, unquote(date()) = to, backend, options)
      when calendar == Calendar.ISO do
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(date()) = from, nil = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(date()) = from, unquote(date()) = to, backend, options) do
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
        Cldr.Date.to_string(from, backend, options)

      other ->
        other
    end
  end

  # Open ended intervals use the `date_time_interval_fallback/0` format
  def to_string(nil, unquote(date()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    cldr_calendar = calendar.cldr_calendar_type

    with {:ok, formatted} <- Cldr.Date.to_string(to, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)
      result =
        ["", formatted]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_leading()

      {:ok, result}
    end
  end

  def to_string(unquote(date()) = from, nil, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    cldr_calendar = calendar.cldr_calendar_type

    with {:ok, formatted} <- Cldr.Date.to_string(from, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)
      result =
        [formatted, ""]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_trailing()

      {:ok, result}
    end
  end

  @doc false
  def to_string!(%Date.Range{first: first, last: last}, backend) do
    to_string!(first, last, backend, [])
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string!(%CalendarInterval{} = interval, backend) do
      to_string!(interval, backend, [])
    end
  end

  @doc """
  Returns a `Date.Range` or `CalendarInterval` as
  a localised string or raises an exception.

  ## Arguments

  * `range` is either a `Date.Range.t` returned from `Date.range/2`
    or a `CalendarInterval.t`

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:date`, `:month_and_day`, `:month`
    and `:year_and_month`. The default is `:date`.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  ## Returns

  * `string` or

  * raises an exception

  ## Notes

  * `CalendarInterval` support requires adding the
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see the `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ## Examples

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-12-31]), MyApp.Cldr
      "Jan 1 – Dec 31, 2020"

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr
      "Jan 1 – 12, 2020"

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long
      "Wed, Jan 1 – Sun, Jan 12, 2020"

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-12-01]), MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      "January – December 2020"

      iex> use CalendarInterval
      iex> Cldr.Date.Interval.to_string! ~I"2020-01/12", MyApp.Cldr
      "Jan 1 – Dec 31, 2020"

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :short
      "1/1/2020 – 1/12/2020"

      iex> Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long, locale: "fr"
      "mer. 1 – dim. 12 janv. 2020"

  """

  @spec to_string!(Cldr.Interval.range(), Cldr.backend(), Keyword.t()) ::
          String.t() | no_return()

  def to_string!(%Date.Range{} = range, backend, options) do
    case to_string(range, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string!(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:year, :month, :day] do
      to_string!(from, to, backend, options)
    end
  end

  @doc """
  Returns a localised string representing the formatted
  interval formed by two dates or raises an
  exception.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.date` type.

  * `to` is any map that conforms to the
    `Calendar.date` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore an `Cldr` backend module

  * `options` is a keyword list of options

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The
    alternatives are `:date`, `:month_and_day`, `:month`
    and `:year_and_month`. The default is `:date`.

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
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ## Examples

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-12-31], MyApp.Cldr
      "Jan 1 – Dec 31, 2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr
      "Jan 1 – 12, 2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long
      "Wed, Jan 1 – Sun, Jan 12, 2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-12-01], MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      "January – December 2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :short
      "1/1/2020 – 1/12/2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long, locale: "fr"
      "mer. 1 – dim. 12 janv. 2020"

      iex> Cldr.Date.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long, locale: "th", number_system: :thai
      "พ. ๑ ม.ค. – อา. ๑๒ ม.ค. ๒๐๒๐"

  """

  @spec to_string!(Calendar.date() | nil, Calendar.date() | nil, Cldr.backend(), Keyword.t()) ::
          String.t() | no_return()

  def to_string!(from, to, backend, options \\ []) do
    case to_string(from, to, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp from_less_than_or_equal_to(from, to) do
    case Date.compare(from, to) do
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
  def datetime_order_error(from, to) do
    {
      Cldr.DateTime.DateTimeOrderError,
      "Start date/time must be earlier or equal to end date/time. " <>
        "Found #{inspect(from)}, #{inspect(to)}."
    }
  end

  @doc false
  def datetime_incompatible_timezone_error(from, to) do
    {
      Cldr.DateTime.IncompatibleTimeZonerError,
      "Start and end dates must be in the same time zone. " <>
        "Found #{inspect(from)}, #{inspect(to)}."
    }
  end

  # Returns the map key for interval formatting
  # based upon the greatest difference between
  # two dates/times represented as a duration.

  # Microseconds and seconds are ignored since they have
  # no format placeholder in interval formats.
  import Cldr.Calendar, only: [date: 0, naivedatetime: 0, datetime: 0, time: 0]

  @doc """
  Returns the format code representing the date or
  time unit that is the greatest difference between
  two dates.

  ## Arguments

  * `from` is any `t:Date.t/0`

  * `to` is any `t:Date.t/0`

  ## Returns

  * `{:ok, format_code}` where `format_code` is one of

    * `:y` meaning that the greatest difference is in the year
    * `:M` meaning that the greatest difference is in the month
    * `:d` meaning that the greatest difference is in the day

  * `{:error, :no_practical_difference}`

  ## Example

      iex> Cldr.Date.Interval.greatest_difference ~D[2022-04-22], ~D[2022-04-23]
      {:ok, :d}

      iex> Cldr.Date.Interval.greatest_difference ~D[2022-04-22], ~D[2022-04-22]
      {:error, :no_practical_difference}

  """
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
