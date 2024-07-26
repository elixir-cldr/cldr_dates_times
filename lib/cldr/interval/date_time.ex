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
  @default_prefer :default

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

    ### Arguments

    * `range` is a `CalendarInterval.t`

    * `backend` is any module that includes `use Cldr` and
      is therefore a `Cldr` backend module

    * `options` is a keyword list of options. The default is `[]`.

    ### Options

    * `:format` is one of `:short`, `:medium` or `:long` or a
      specific format type or a string representing of an interval
      format. The default is `:medium`.

    * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the date part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
      then the date format is defined by the `:format` option.

    * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the time part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
      then the time format is defined by the `:format` option.

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`

    * `:number_system` a number system into which the formatted date digits should
      be transliterated.

    * `:prefer` expresses the preference for one of the possible alternative
      sub-formats. See the variant preference notes below.

    ### Variant Preference

    * A small number of formats have one of two different alternatives, each with their own
      preference specifier. The preferences are specified with the `:prefer` option to
      `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
      atoms with one atom being either `:unicode` or `:ascii` and one atom being either
      `:default` or `:variant`.

      * Some formats (at the time of publishng only time formats but that
        may change in the future) have `:unicode` and `:ascii` versions of the format. The
        difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
        whereas the `:unicode` version may use non-breaking or other space characters. The
        default is `:unicode` and this is the strongly preferred option. The `:ascii` format
        is primarily to support legacy use cases and is not recommended. See
        `Cldr.Date.available_formats/3` to see which formats have these variants.

      * Some formats (at the time of publishing, only date and datetime formats) have
        `:default` and `:variant` versions of the format. These variant formats are only
        included in a small number of locales. For example, the `:"en-CA"` locale, which has
        a `:default` format respecting typical Canadian formatting and a `:variant` that is
        more closely aligned to US formatting. The default is `:default`.

    ### Returns

    * `{:ok, string}` or

    * `{:error, {exception, reason}}`

    ### Notes

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

    ### Examples

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
    options = Keyword.put_new(options, :locale, locale)
    to_string(from, to, backend, options)
  end

  def to_string(nil = from, unquote(naivedatetime()) = to, options)
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(from, to, backend, options)
  end

  def to_string(unquote(naivedatetime()) = from, nil = to, options)
      when is_list(options) do
    _ = calendar

    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(from, to, backend, options)
  end

  @doc """
  Returns a localised string representing the formatted
  interval formed by two dates.

  ### Arguments

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

  ### Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representation of an interval
    format. The default is `:medium`.

  * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
    this option is used to format the date part of the date time. This option is
    only acceptable if the `:format` option is not specified, or is specified as either
    `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
    then the date format is defined by the `:format` option.

  * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
    this option is used to format the time part of the date time. This option is
    only acceptable if the `:format` option is not specified, or is specified as either
    `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
    thenthe time format is defined by the `:format` option.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`

  * `:number_system` a number system into which the formatted date digits should
    be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

  ### Variant Preference

  * A small number of formats have one of two different alternatives, each with their own
    preference specifier. The preferences are specified with the `:prefer` option to
    `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
    atoms with one atom being either `:unicode` or `:ascii` and one atom being either
    `:default` or `:variant`.

    * Some formats (at the time of publishng only time formats but that
      may change in the future) have `:unicode` and `:ascii` versions of the format. The
      difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
      whereas the `:unicode` version may use non-breaking or other space characters. The
      default is `:unicode` and this is the strongly preferred option. The `:ascii` format
      is primarily to support legacy use cases and is not recommended. See
      `Cldr.Date.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only date and datetime formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Returns

  * `{:ok, string}` or

  * `{:error, {exception, reason}}`

  ### Notes

  * For more information on interval format string
    see the `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ### Examples

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
    options = normalize_options(from, backend, options)
    format = options.format
    locale = options.locale
    backend = options.backend
    number_system = options.number_system

    date_format = Map.get(options, :date_format)
    time_format = Map.get(options, :time_format)

    with {:ok, _} <- from_less_than_or_equal_to(from, to),
         {:ok, backend} <- Cldr.validate_backend(backend),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, calendar} <- Cldr.Calendar.validate_calendar(from.calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         {:ok, format, date_format, time_format} <-
           validate_format(format, date_format, time_format, options),
         {:ok, greatest_difference} <- greatest_difference(from, to) do
      options = adjust_options(options, locale, format, date_format, time_format)
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
    cldr_calendar = calendar.cldr_calendar_type()

    with {:ok, formatted} <- Cldr.DateTime.to_string(to, backend, options) do
      pattern =
        Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)

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
    cldr_calendar = calendar.cldr_calendar_type()

    with {:ok, formatted} <- Cldr.DateTime.to_string(from, backend, options) do
      pattern =
        Module.concat(backend, DateTime.Format).date_time_interval_fallback(locale, cldr_calendar)

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

    ### Arguments

    * `from` is any map that conforms to the
      `Calendar.datetime` type.

    * `to` is any map that conforms to the
      `Calendar.datetime` type. `to` must occur
      on or after `from`.

    * `backend` is any module that includes `use Cldr` and
      is therefore a `Cldr` backend module.

    * `options` is a keyword list of options. The default is `[]`.

    ### Options

    * `:format` is one of `:short`, `:medium` or `:long` or a
      specific format type or a string representing of an interval
      format. The default is `:medium`.

    * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the date part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
      then the date format is defined by the `:format` option.

    * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the time part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
      then the time format is defined by the `:format` option.

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

    * `:number_system` a number system into which the formatted date digits should
      be transliterated.

    * `:prefer` expresses the preference for one of the possible alternative
      sub-formats. See the variant preference notes below.

    ### Variant Preference

    * A small number of formats have one of two different alternatives, each with their own
      preference specifier. The preferences are specified with the `:prefer` option to
      `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
      atoms with one atom being either `:unicode` or `:ascii` and one atom being either
      `:default` or `:variant`.

      * Some formats (at the time of publishng only time formats but that
        may change in the future) have `:unicode` and `:ascii` versions of the format. The
        difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
        whereas the `:unicode` version may use non-breaking or other space characters. The
        default is `:unicode` and this is the strongly preferred option. The `:ascii` format
        is primarily to support legacy use cases and is not recommended. See
        `Cldr.Date.available_formats/3` to see which formats have these variants.

      * Some formats (at the time of publishing, only date and datetime formats) have
        `:default` and `:variant` versions of the format. These variant formats are only
        included in a small number of locales. For example, the `:"en-CA"` locale, which has
        a `:default` format respecting typical Canadian formatting and a `:variant` that is
        more closely aligned to US formatting. The default is `:default`.

    ### Returns

    * `string` or

    * raises an exception

    ### Notes

    * For more information on interval format string
      see the `Cldr.Interval`.

    * The available predefined formats that can be applied are the
      keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
      where `"en"` can be replaced by any configuration locale name and `:gregorian`
      is the underlying CLDR calendar type.

    * In the case where `from` and `to` are equal, a single
      date is formatted instead of an interval.

    ### Examples

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

  ### Arguments

  * `from` is any map that conforms to the
    `Calendar.datetime` type.

  * `to` is any map that conforms to the
    `Calendar.datetime` type. `to` must occur
    on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module.

  * `options` is a keyword list of options. The default is `[]`.

  ### Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representation of an interval
    format. The default is `:medium`.

  * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
    this option is used to format the date part of the date time. This option is
    only acceptable if the `:format` option is not specified, or is specified as either
    `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
    then the date format is defined by the `:format` option.

  * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
    this option is used to format the time part of the date time. This option is
    only acceptable if the `:format` option is not specified, or is specified as either
    `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
    then the time format is defined by the `:format` option.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted date digits should
    be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

  ### Variant Preference

  * A small number of formats have one of two different alternatives, each with their own
    preference specifier. The preferences are specified with the `:prefer` option to
    `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
    atoms with one atom being either `:unicode` or `:ascii` and one atom being either
    `:default` or `:variant`.

    * Some formats (at the time of publishng only time formats but that
      may change in the future) have `:unicode` and `:ascii` versions of the format. The
      difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
      whereas the `:unicode` version may use non-breaking or other space characters. The
      default is `:unicode` and this is the strongly preferred option. The `:ascii` format
      is primarily to support legacy use cases and is not recommended. See
      `Cldr.Date.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only date and datetime formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Returns

  * `string` or

  * raises an exception

  ### Notes

  * For more information on interval format string
    see the `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date is formatted instead of an interval

  ### Examples

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

  ### Arguments

  * `from` is any `t:DateTime.t/0` or `t:NaiveDateTine.t/0`

  * `to` is any `t:DateTime.t/0` or `t:NaiveDateTine.t/0`

  ### Returns

  * `{:ok, format_code}` where `format_code` is one of

    * `:y` meaning that the greatest difference is in the year
    * `:M` meaning that the greatest difference is in the month
    * `:d` meaning that the greatest difference is in the day
    * `:H` meaning that the greatest difference is in the hour
    * `:m` meaning that the greatest difference is in the minute

  * `{:error, :no_practical_difference}`

  ### Example

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

  defp normalize_options(from, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)
    prefer = Keyword.get(options, :prefer, @default_prefer) |> List.wrap()
    format = Keyword.get(options, :format, @default_format)

    options
    |> Map.new()
    |> Map.put(:format, format)
    |> Map.put(:locale, locale)
    |> Map.put(:number_system, number_system)
    |> Map.put(:backend, backend)
    |> Map.put(:calendar, from.calendar)
    |> Map.put(:prefer, prefer)
  end

  @doc false
  def adjust_options(options, locale, format, date_format \\ nil, time_format \\ nil) do
    options
    |> Map.put(:locale, locale)
    |> Map.put(:format, format)
    |> Map.put(:date_format, date_format)
    |> Map.put(:time_format, time_format)
    |> Map.delete(:style)
  end

  defp format_date_time(from, to, locale, backend, calendar, difference, options) do
    backend_format = Module.concat(backend, DateTime.Format)
    {:ok, calendar} = Cldr.DateTime.type_from_calendar(calendar)
    fallback = backend_format.date_time_interval_fallback(locale, calendar)
    format = Map.fetch!(options, :format)

    [from_format, to_format] = extract_format(format, difference, options)
    from_options = Map.put(options, :format, from_format)
    to_options = Map.put(options, :format, to_format)
    final_format = if is_atom(format), do: format, else: [from_format, to_format]

    do_format_date_time(
      from,
      to,
      backend,
      final_format,
      difference,
      from_options,
      to_options,
      fallback
    )
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

  defp extract_format(format, _distance, options) when is_atom(format) do
    case options do
      %{time_format: nil, date_format: nil} ->
        [format, format]

      %{time_format: time_format, date_format: nil} ->
        [format, time_format]

      %{time_format: nil, date_format: date_format} ->
        [date_format, format]

      %{time_format: time_format, date_format: date_format} ->
        [date_format, time_format]
    end
  end

  defp extract_format(format, distance, options) when is_map(format) do
    format = Map.fetch!(format, distance)

    case format do
      %{default: default, variant: variant} ->
        if :variant in options.prefer, do: variant, else: default

      other ->
        other
    end
  end

  defp extract_format([from_format, to_format], _greatest_distance, _prefer) do
    [from_format, to_format]
  end

  # Using standard format terms like :short, :medium, :long
  # When there is no specific date or time format requested
  defp validate_format(format, nil, nil, _options) when format in @formats do
    {:ok, format, nil, nil}
  end

  # Using standard format terms like :short, :medium, :long
  # with date and time formats also of the same style
  defp validate_format(format, date_format, time_format, _options)
       when format in @formats and date_format in @formats and time_format in @formats do
    {:ok, format, date_format, time_format}
  end

  # Using standard format terms like :short, :medium, :long
  # with date format specified but time format
  # uses the interval format
  defp validate_format(format, date_format, nil, _options)
       when format in @formats and date_format in @formats do
    {:ok, format, date_format, format}
  end

  # Using standard format terms like :short, :medium, :long
  # with time format specified but date format
  # uses the interval format
  defp validate_format(format, nil, time_format, _options)
       when format in @formats and time_format in @formats do
    {:ok, format, format, time_format}
  end

  # Direct specification of a format as a string
  defp validate_format(format, nil, nil, _options) when is_binary(format) do
    with {:ok, format} <- Cldr.DateTime.Format.split_interval(format) do
      {:ok, format, nil, nil}
    end
  end

  # Direct specification of a format as a string
  defp validate_format(format, nil, nil, options) when is_atom(format) do
    alias Cldr.DateTime.Format

    locale = options.locale
    backend = options.backend
    {:ok, cldr_calendar} = Cldr.DateTime.type_from_calendar(options.calendar)

    with {:ok, interval_formats} <- Format.interval_formats(locale, cldr_calendar, backend) do
      if format = Map.get(interval_formats, format) do
        {:ok, format, nil, nil}
      else
        {:error, format_error(format, nil, nil)}
      end
    end
  end

  # If the format is binary then neither date or time format can be
  # specified.
  defp validate_format(format, date_format, time_format, _options) when is_binary(format) do
    {:error, format_error(format, date_format, time_format)}
  end

  defp validate_format(format, date_format, time_format, _options) do
    {:error, format_error(format, date_format, time_format)}
  end

  @doc false
  def format_error(format, date_format \\ nil, time_format \\ nil)

  def format_error(format, nil, nil) do
    {
      Cldr.DateTime.InvalidFormat,
      "The interval format #{inspect(format)} is invalid. " <>
        "Valid formats are #{inspect(@formats)} or an interval format string.}"
    }
  end

  def format_error(format, date_format, time_format) when format in @formats do
    {
      Cldr.DateTime.InvalidFormat,
      ":date_format and :time_format must be one of " <>
        inspect(@formats) <>
        " if :format is also one of #{inspect(@formats)}. Found #{inspect(date_format)} and #{inspect(time_format)}."
    }
  end

  def format_error(format, date_format, time_format)
      when is_binary(format)
      when not is_nil(date_format) and not is_nil(time_format) do
    {
      Cldr.DateTime.InvalidFormat,
      ":date_format and :time_format " <> error_string(format) <> "."
    }
  end

  def format_error(format, date_format, nil) when is_binary(format) and not is_nil(date_format) do
    {
      Cldr.DateTime.InvalidFormat,
      ":date_format " <> error_string(format) <> "."
    }
  end

  def format_error(format, nil, time_format) when is_binary(format) and not is_nil(time_format) do
    {
      Cldr.DateTime.InvalidFormat,
      ":time_format " <> error_string(format) <> "."
    }
  end

  defp error_string(format) do
    "cannot be specified when the interval format is a binary or atom other than one of #{inspect(@formats)}. Found: #{inspect(format)}"
  end
end
