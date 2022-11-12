defmodule Cldr.DateTime.Interval do
  @moduledoc """
  Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
  shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
  to take a start and end date, time or datetime plus a formatting pattern
  and use that information to produce a localized format.

  See `Cldr.Interval.to_string/3` and `Cldr.DateTime.Interval.to_string/3`

  """

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

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string(%CalendarInterval{} = interval, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string(interval, backend, locale: locale)
    end

    @doc false
    def to_string(%CalendarInterval{} = interval, options) when is_list(options) do
      {locale, backend} = Cldr.locale_and_backend_from(options)
      to_string(interval, backend, locale: locale)
    end

    @doc """
    Returns a localised string representing the formatted
    `CalendarInterval`.

    ## Arguments

    * `range` is a `CalendarInterval.t`

    * `backend` is any module that includes `use Cldr` and
      is therefore a `Cldr` backend module

    * `options` is a keyword list of options. The default is `[]`.

    ## Options

    * `:format` is one of `:short`, `:medium` or `:long` or a
      specific format type or a string representing of an interval
      format. The default is `:medium`.

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

    * `number_system:` a number system into which the formatted date digits should
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
      datetime is formatted instead of an interval

    ## Examples

        iex> Cldr.DateTime.Interval.to_string ~I"2020-01-01 10:00/12:00", MyApp.Cldr
        {:ok, "Jan 1, 2020, 10:00:00 AM – 12:00:00 PM"}

    """
    @spec to_string(CalendarInterval.t(), Cldr.backend(), Keyword.t()) ::
            {:ok, String.t()} | {:error, {module, String.t()}}

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:year, :month, :day] do
      Cldr.Date.Interval.to_string(from, to, backend, options)
    end

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:hour, :minute] do
      from = %{from | second: 0, microsecond: {0, 6}}
      to = %{to | second: 0, microsecond: {0, 6}}
      to_string(from, to, backend, options)
    end

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:hour, :minute] do
      from = %{from | microsecond: {0, 6}}
      to = %{to | microsecond: {0, 6}}
      to_string(from, to, backend, options)
    end
  end

  @doc false
  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(naivedatetime()) = to) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(naivedatetime()) = from, nil = to) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  @doc false
  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend)
      when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(naivedatetime()) = to, backend)
      when is_atom(backend) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(naivedatetime()) = from, nil = to, backend)
      when is_atom(backend) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  @doc false
  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, options)
      when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(nil = from, unquote(naivedatetime()) = to, options)
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(naivedatetime()) = from, nil = to, options)
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, locale: locale)
  end

  @doc """
  Returns a localised string representing the formatted
  interval formed by two dates.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.datetime` type.

  * `to` is any map that conforms to the
    `Calendar.datetime` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  Either of `from` or `to` may also be `nil` in which case the
  result is an "open" interval and the non-nil parameter is formatted
  using `Cldr.DateTime.to_string/3`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representation of an interval
    format. The default is `:medium`.

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

      iex> Cldr.DateTime.Interval.to_string ~U[2020-01-01 00:00:00.0Z],
      ...> ~U[2020-12-31 10:00:00.0Z], MyApp.Cldr
      {:ok, "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"}

      iex> Cldr.DateTime.Interval.to_string ~U[2020-01-01 00:00:00.0Z], nil, MyApp.Cldr
      {:ok, "Jan 1, 2020, 12:00:00 AM –"}

  """
  @spec to_string(Calendar.datetime() | nil, Calendar.datetime() | nil, Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(from, to, backend, options \\ [])

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(nil = from, unquote(naivedatetime()) = to, backend, options)
      when calendar == Calendar.ISO do
    to = %{to | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(naivedatetime()) = from, nil = to, backend, options)
      when calendar == Calendar.ISO do
    from = %{from | calendar: Cldr.Calendar.Gregorian}

    to_string(from, to, backend, options)
  end

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, options, [])
      when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(naivedatetime()) = from, nil = to, options, [])
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(nil = from, unquote(naivedatetime()) = to, options, [])
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(from, to, backend, Keyword.put_new(options, :locale, locale))
  end

  def to_string(unquote(naivedatetime()) = from, unquote(naivedatetime()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
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

  # Open ended intervals use the `date_time_interval_fallback/0` format
  def to_string(nil, unquote(naivedatetime()) = to, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    cldr_calendar = calendar.cldr_calendar_type

    with {:ok, formatted} <- Cldr.DateTime.to_string(to, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)
      result =
        ["", formatted]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_leading()

      {:ok, result}
    end
  end

  def to_string(unquote(naivedatetime()) = from, nil, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    cldr_calendar = calendar.cldr_calendar_type

    with {:ok, formatted} <- Cldr.DateTime.to_string(from, backend, options) do
      pattern = Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)
      result =
        [formatted, ""]
        |> Cldr.Substitution.substitute(pattern)
        |> Enum.join()
        |> String.trim_trailing()

      {:ok, result}
    end
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string!(%CalendarInterval{} = range, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string!(range, backend, locale: locale)
    end

    @doc false
    def to_string!(%CalendarInterval{} = range, options) when is_list(options) do
      {locale, backend} = Cldr.locale_and_backend_from(options[:locale], nil)
      options = Keyword.put_new(options, :locale, locale)
      to_string!(range, backend, options)
    end
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc """
    Returns a localised string representing the formatted
    interval formed by two dates or raises an
    exception.

    ## Arguments

    * `from` is any map that conforms to the
      `Calendar.datetime` type.

    * `to` is any map that conforms to the
      `Calendar.datetime` type. `to` must occur
      on or after `from`.

    * `backend` is any module that includes `use Cldr` and
      is therefore a `Cldr` backend module.

    * `options` is a keyword list of options. The default is `[]`.

    ## Options

    * `:format` is one of `:short`, `:medium` or `:long` or a
      specific format type or a string representing of an interval
      format. The default is `:medium`.

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

    * `number_system:` a number system into which the formatted date digits should
      be transliterated.

    ## Returns

    * `string` or

    * raises an exception

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

        iex> use CalendarInterval
        iex> Cldr.DateTime.Interval.to_string! ~I"2020-01-01 00:00/10:00", MyApp.Cldr
        "Jan 1, 2020, 12:00:00 AM – 10:00:59 AM"

    """

    @spec to_string!(CalendarInterval.t(), Cldr.backend(), Keyword.t()) ::
            String.t() | no_return

    def to_string!(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:year, :month, :day] do
      Cldr.Date.Interval.to_string!(from, to, backend, options)
    end

    def to_string!(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:hour, :minute, :second] do
      to_string!(from, to, backend, options)
    end
  end

  @doc """
  Returns a localised string representing the formatted
  interval formed by two dates or raises an
  exception.

  ## Arguments

  * `from` is any map that conforms to the
    `Calendar.datetime` type.

  * `to` is any map that conforms to the
    `Calendar.datetime` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module.

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representation of an interval
    format. The default is `:medium`.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

  * `number_system:` a number system into which the formatted date digits should
    be transliterated.

  ## Returns

  * `string` or

  * raises an exception

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

      iex> Cldr.DateTime.Interval.to_string! ~U[2020-01-01 00:00:00.0Z],
      ...> ~U[2020-12-31 10:00:00.0Z], MyApp.Cldr
      "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"

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
  two date/times.

  ## Arguments

  * `from` is any `t:DateTime.t/0` or `t:NaiveDateTine.t/0`

  * `to` is any `t:DateTime.t/0` or `t:NaiveDateTine.t/0`

  ## Returns

  * `{:ok, format_code}` where `format_code` is one of

    * `:y` meaning that the greatest difference is in the year
    * `:M` meaning that the greatest difference is in the month
    * `:d` meaning that the greatest difference is in the day
    * `:H` meaning that the greatest difference is in the hour
    * `:m` meaning that the greatest difference is in the minute

  * `{:error, :no_practical_difference}`

  ## Example

      iex> Cldr.DateTime.Interval.greatest_difference ~U[2022-04-22 02:00:00.0Z], ~U[2022-04-22 03:00:00.0Z]
      {:ok, :H}

      iex> Cldr.DateTime.Interval.greatest_difference ~U[2022-04-22 02:00:00.0Z], ~U[2022-04-22 02:00:01.0Z]
      {:error, :no_practical_difference}

  """
  def greatest_difference(from, to) do
    Cldr.Date.Interval.greatest_difference(from, to)
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
