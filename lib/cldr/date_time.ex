defmodule Cldr.DateTime do
  @moduledoc """
  Provides localization and formatting of a datetime.

  A date time is any `t:DateTime.t/0` or `t:NaiveDateTime.t/0`
  struct or any map that contains one or more of the keys `:year`, `:month`, `:day`,
  `:hour`, `:minute` and `:second` or `:microsecond` with optional `:time_zone`, `:zone_abbr`,
  `:utc_offset`, `:std_offset` and `:calendar` fields.

  `Cldr.DateTime` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  CLDR provides standard format strings for `t:DateTime.t/0` which
  are represented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale and calendar will define the underlying
  format string as appropriate.

  """

  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag
  alias Cldr.Locale

  @typep options :: Keyword.t() | map()

  @format_types [:short, :medium, :long, :full]
  @default_format_type :medium
  @default_style :default
  @default_prefer :unicode

  @doc """
  Indicates if a given map fulfills the requirements
  for a naive date time.
  """
  defguard is_naive_date_time(datetime)
           when is_map_key(datetime, :year) and
                  is_map_key(datetime, :month) and
                  is_map_key(datetime, :day) and
                  is_map_key(datetime, :hour) and
                  is_map_key(datetime, :minute) and
                  is_map_key(datetime, :second)

  @doc """
  Indicates if a given map fulfills the requirements
  for a date time.
  """
  defguard is_date_time(datetime)
           when is_naive_date_time(datetime) and
                  is_map_key(datetime, :time_zone) and
                  is_map_key(datetime, :zone_abbr)

  @doc """
  Indicates if a given map fulfills the requirements
  for a naive date time or date time.
  """
  defguard is_any_date_time(datetime)
           when is_date_time(datetime) or is_naive_date_time(datetime)

  @doc """
  Guards whether the given datetime has components of
  a date.
  """
  defguard has_date(datetime)
           when is_map_key(datetime, :year) or is_map_key(datetime, :month) or
                  is_map_key(datetime, :day)

  @doc """
  Guards whether the given datetime has components of
  a time.
  """
  defguard has_time(datetime)
           when is_map_key(datetime, :hour) or is_map_key(datetime, :minute) or
                  is_map_key(datetime, :second)

  @doc """
  Guard whether the given datetime has components of
  both a date and a time.
  """
  defguard has_date_and_time(datetime)
           when has_date(datetime) and has_time(datetime)

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.DateTime, :format_types)
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ### Arguments

  * `datetime` is a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
    `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
    and `:calendar` fields.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format ID
    or a format string. The default is `:medium` for full datetimes (that is,
    dates having `:year`, `:month`, `:day`, `:hour`, `:minutes`, `:second` and
    `:calendar` fields). The default for partial datetimes is to derive a candidate
    format ID from the date and find the best match from the formats returned by
    `Cldr.DateTime.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

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

  * `:style` is either `:at` or `:default`. When set to `:at` the datetime may
    be formatted with a localised string representing `<date> at <time>` if such
    a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

  * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
    formats have two variants - one using Unicode spaces (typically non-breaking space) and
    another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
    use cases and is not recommended. See `Cldr.DateTime.Format.date_time_available_formats/3`
    to see which formats have these variants.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted datetime digits should
    be transliterated.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

  * `period: :variant` will use a variant for the time period and flexible time period if
    one is available in the locale.  For example, in the `:en` locale `period: :variant` will
    return "pm" instead of "PM".

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
      `Cldr.Time.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only date and datetime formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Notes

  * If the provided `datetime` contains only date fields, the call is delegated to
    `Cldr.Date.to_string/2`.

  * If the provided `datetime` contains only time fields, the call is delegated to
    `Cldr.Time.to_string/2`.

  ### Returns

  * `{:ok, formatted_datetime}` or

  * `{:error, reason}`

  ### Examples

      iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string(date_time)
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, locale: :en)
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :long, locale: :en)
      {:ok, "January 1, 2000, 11:59:59 PM UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :hms, locale: :en)
      {:ok, "11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, locale: :en)
      {:ok, "Saturday, January 1, 2000, 11:59:59 PM GMT"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, locale: :fr)
      {:ok, "samedi 1 janvier 2000, 23:59:59 UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :en)
      {:ok, "Saturday, January 1, 2000 at 11:59:59 PM GMT"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :fr)
      {:ok, "samedi 1 janvier 2000 à 23:59:59 UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      {:ok, "semaine 1 (janvier)"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      {:ok, "semaine 1 de 2000"}

  """
  @spec to_string(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  @spec to_string(Cldr.Calendar.any_date_time(), options(), []) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(datetime, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = datetime, backend, options) do
    %{datetime | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(datetime, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(datetime, backend, options)
  end

  def to_string(%{} = datetime, backend, options)
      when is_atom(backend) and has_date_and_time(datetime) do
    format_backend = Module.concat(backend, DateTime.Formatter)

    with {:ok, datetime, options} <- normalize_options(datetime, backend, options),
         {:ok, locale} <- Cldr.validate_locale(options.locale, backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(datetime.calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, options.number_system, backend),
         {:ok, format, options} <-
           find_format(datetime, options.format, locale, cldr_calendar, backend, options),
         {:ok, format} <- apply_preference(format, options.prefer),
         {:ok, format_string} <- resolve_plural_format(format, datetime, backend, options) do
      format_backend.format(datetime, format_string, locale, options)
    end
  rescue
    e in [Cldr.DateTime.FormatError] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(%{} = datetime, backend, options)
      when is_atom(backend) and has_date(datetime) do
    Cldr.Date.to_string(datetime, backend, options)
  end

  def to_string(%{} = datetime, backend, options)
      when is_atom(backend) and has_time(datetime) do
    Cldr.Time.to_string(datetime, backend, options)
  end

  def to_string(datetime, value, []) when is_map(datetime) do
    {:error, {ArgumentError, "Unexpected option value #{inspect value}. Options must be a keyword list"}}
  end

  def to_string(datetime, _backend, _options) do
    error_return(datetime, [:year, :month, :day, :hour, :minute, :second, :calendar])
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
  returning a formatted string or raising on error.

  ### Arguments

  * `datetime` is a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
    `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
    and `:calendar` fields.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format ID
    or a format string. The default is `:medium` for full datetimes (that is,
    dates having `:year`, `:month`, `:day`, `:hour`, `:minutes`, `:second` and
    `:calendar` fields). The default for partial datetimes is to derive a candidate
    format ID from the date and find the best match from the formats returned by
    `Cldr.DateTime.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

  * `:style` is either `:at` or `:default`. When set to `:at` the datetime may
    be formatted with a localised string representing `<date> at <time>` if such
    a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

  * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of datetime
    formats have two variants - one using Unicode spaces (typically non-breaking space) and
    another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
    use cases and is not recommended. See `Cldr.DateTime.Format.date_time_available_formats/2`
    to see which formats have these variants.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted datetime digits should
    be transliterated.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

  * `period: :variant` will use a variant for the time period and flexible time period if
    one is available in the locale.  For example, in the `:en` locale `period: :variant` will
    return "pm" instead of "PM".

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
      `Cldr.Time.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only date and datetime formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Notes

  * If the provided `datetime` contains only date fields, the call is delegated to
    `Cldr.Date.to_string/2`.

  * If the provided `datetime` contains only time fields, the call is delegated to
    `Cldr.Time.to_string/2`.

  ### Returns

  * `formatted_datetime` or

  * raises an exception

  ### Examples

      iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, locale: :en)
      "Jan 1, 2000, 11:59:59 PM"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :long, locale: :en)
      "January 1, 2000, 11:59:59 PM UTC"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :en)
      "Saturday, January 1, 2000, 11:59:59 PM GMT"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :fr)
      "samedi 1 janvier 2000, 23:59:59 UTC"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      "semaine 1 (janvier)"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      "semaine 1 de 2000"

  """
  @spec to_string!(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          String.t() | no_return()

  @spec to_string!(Cldr.Calendar.any_date_time(), options(), []) ::
          String.t() | no_return()

  def to_string!(datetime, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(datetime, backend, options) do
    case to_string(datetime, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @doc """
  Returns a map of the standard datetime formats for a given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_formats(:en)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

      iex> Cldr.DateTime.Format.date_time_formats(:en, :buddhist, MyApp.Cldr)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

  """
  @spec formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    Cldr.DateTime.Format.date_time_formats(locale, calendar, backend)
  end

  @doc """
  Returns a map of the available datetime formats for a
  given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.available_formats(:en)
      {:ok,
       %{
         yw: %{
           other: "'week' w 'of' Y",
           one: "'week' w 'of' Y",
           pluralize: :week_of_year
         },
         GyMMMEd: "E, MMM d, y G",
         Hms: "HH:mm:ss",
         MMMMW: %{
           other: "'week' W 'of' MMMM",
           one: "'week' W 'of' MMMM",
           pluralize: :week_of_month
         },
         E: "ccc",
         MMMd: "MMM d",
         yMEd: "E, M/d/y",
         yQQQ: "QQQ y",
         Ehm: %{unicode: "E h:mm a", ascii: "E h:mm a"},
         M: "L",
         hm: %{unicode: "h:mm a", ascii: "h:mm a"},
         yM: "M/y",
         GyMMMd: "MMM d, y G",
         GyMd: "M/d/y G",
         Gy: "y G",
         Hm: "HH:mm",
         EBhms: "E h:mm:ss B",
         d: "d",
         hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         Ed: "d E",
         Ehms: %{unicode: "E h:mm:ss a", ascii: "E h:mm:ss a"},
         EHms: "E HH:mm:ss",
         Bh: "h B",
         h: %{unicode: "h a", ascii: "h a"},
         Bhms: "h:mm:ss B",
         Hmv: "HH:mm v",
         hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"},
         yMd: "M/d/y",
         ms: "mm:ss",
         MMM: "LLL",
         y: "y",
         Bhm: "h:mm B",
         yMMM: "MMM y",
         yQQQQ: "QQQQ y",
         yMMMEd: "E, MMM d, y",
         yMMMM: "MMMM y",
         EBhm: "E h:mm B",
         Hmsv: "HH:mm:ss v",
         yMMMd: "MMM d, y",
         MEd: "E, M/d",
         EHm: "E HH:mm",
         GyMMM: "MMM y G",
         hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
         H: "HH",
         Md: "M/d",
         MMMEd: "E, MMM d",
         MMMMd: "MMMM d"
       }}

  """
  @spec available_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}

  def available_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    Format.date_time_available_formats(locale, calendar, backend)
  end

  defp normalize_options(datetime, backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)

    calendar = Map.get(datetime, :calendar, Cldr.Calendar.Gregorian)
    datetime = Map.put_new(datetime, :calendar, calendar)

    {format, date_format, time_format} =
      formats_from_options(datetime, nil, nil, nil, @default_format_type)

    options =
      %{
        locale: locale,
        number_system: number_system,
        format: format,
        date_format: date_format,
        time_format: time_format,
        style: @default_style,
        prefer: [@default_prefer]
      }

    {:ok, datetime, options}
  end

  defp normalize_options(datetime, _backend, options) when is_map(options) do
    {:ok, datetime, options}
  end

  defp normalize_options(datetime, backend, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)

    calendar = Map.get(datetime, :calendar, Cldr.Calendar.Gregorian)
    datetime = Map.put_new(datetime, :calendar, calendar)

    style = options[:style] || @default_style
    prefer = Keyword.get(options, :prefer, @default_prefer) |> List.wrap()

    format = options[:format]
    date_format = options[:date_format]
    time_format = options[:time_format]

    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)

    {format, date_format, time_format} =
      formats_from_options(datetime, format, date_format, time_format, @default_format_type)

    with :ok <- validate_formats_consistent(format, date_format, time_format) do
      options =
        options
        |> Map.new()
        |> Map.put(:locale, locale)
        |> Map.put(:format, format)
        |> Map.put(:date_format, date_format)
        |> Map.put(:time_format, time_format)
        |> Map.put(:style, style)
        |> Map.put(:prefer, prefer)
        |> Map.put(:number_system, number_system)

      {:ok, datetime, options}
    end
  end

  defp validate_formats_consistent(format, nil = _date_format, nil = _time_format)
       when is_atom(format) or is_binary(format) do
    :ok
  end

  defp validate_formats_consistent(nil, date_format, time_format)
       when not is_nil(date_format) and not is_nil(time_format) do
    :ok
  end

  defp validate_formats_consistent(format, date_format, time_format)
       when format in @format_types and date_format in @format_types and
              time_format in @format_types do
    :ok
  end

  defp validate_formats_consistent(format, date_format, time_format)
       when is_atom(format) or is_binary(format) do
    {:error,
     {Cldr.DateTime.InvalidFormat,
      ":date_format and :time_format cannot be specified if :format is also specified as " <>
        "a format id or a format string. Found [time_format: #{inspect(time_format)}, " <>
        "date_format: #{inspect(date_format)}]"}}
  end

  # Returns the CLDR calendar type for a calendar
  @doc false
  def type_from_calendar(Cldr.Calendar.Gregorian = calendar) do
    {:ok, calendar.cldr_calendar_type()}
  end

  def type_from_calendar(calendar) do
    with {:ok, calendar} <- Cldr.Calendar.validate_calendar(calendar) do
      {:ok, calendar.cldr_calendar_type()}
    end
  end

  # There are three formats required to format a date time:
  # 1. A format for the date part, if any.
  # 2. A format for the time part, if any.
  # 3. A format for how to combine the two parts.

  # All formats are optional - they can be derived. See
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons and
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Missing_Skeleton_Fields

  # When we have a standard format then we use the same format name for
  # the date and the time.
  defp formats_from_options(datetime, nil, nil, nil, _default)
       when is_any_date_time(datetime) do
    {@default_format_type, @default_format_type, @default_format_type}
  end

  defp formats_from_options(_datetime, format, nil, nil, _default)
       when format in @format_types do
    {format, format, format}
  end

  # When we have a string or atom format then it controls everything and there
  # should be no separate date format or time format
  defp formats_from_options(_datetime, format, nil, nil, _default)
       when is_binary(format) do
    {format, nil, nil}
  end

  defp formats_from_options(_datetime, format, nil, nil, _default)
       when is_atom(format) do
    {format, nil, nil}
  end

  # Replace nil date and time formats with the format iff format is
  # one of the standard types.
  defp formats_from_options(_datetime, format, date_format, nil, _default)
       when format in @format_types do
    {format, date_format, format}
  end

  defp formats_from_options(_datetime, format, nil, time_format, _default)
       when format in @format_types do
    {format, format, time_format}
  end

  defp formats_from_options(_datetime, format, nil, time_format, _default)
       when time_format in @format_types do
    {format, time_format, time_format}
  end

  defp formats_from_options(_datetime, format, date_format, nil, _default)
       when date_format in @format_types do
    {format, date_format, date_format}
  end

  # If standard date and time formats but no format, we'll derive the
  # format later on.
  defp formats_from_options(_datetime, nil = format, date_format, time_format, _default)
       when date_format in @format_types and time_format in @format_types do
    {format, date_format, time_format}
  end

  defp formats_from_options(_datetime, format, date_format, time_format, _default) do
    {format, date_format, time_format}
  end

  # Resolve the actual format string for the date time format.
  # Unless we need to derive the format, this only touches `format`,
  # not `date_format` or `time_format`.

  # Standard format, at style
  defp find_format(_datetime, format, locale, calendar, backend, %{style: :at} = options)
       when format in @format_types do
    %LanguageTag{cldr_locale_name: locale_name} = locale

    with {:ok, formats} <- Format.date_time_at_formats(locale_name, calendar, backend),
         {:ok, format} <- preferred_format(formats, format, options.prefer) do
      {:ok, format, options}
    end
  end

  # Standard format, standard style
  defp find_format(_datetime, format, locale, calendar, backend, options)
       when format in @format_types do
    %LanguageTag{cldr_locale_name: locale_name} = locale

    with {:ok, formats} <- Format.date_time_formats(locale_name, calendar, backend),
         {:ok, format} <- preferred_format(formats, format, options.prefer) do
      {:ok, format, options}
    end
  end

  # Look up for the format in :available_formats
  defp find_format(_datetime, format, locale, calendar, backend, options)
       when is_atom(format) and not is_nil(format) do
    %LanguageTag{cldr_locale_name: locale_name} = locale

    with {:ok, formats} <- Format.date_time_available_formats(locale_name, calendar, backend),
         {:ok, format} <- preferred_format(formats, format, options.prefer) do
      {:ok, format, options}
    end
  end

  # Straight up format string
  defp find_format(_datetime, format, _locale, _calendar, _backend, options)
       when is_binary(format) do
    {:ok, format, options}
  end

  # Format with a number system
  defp find_format(datetime, %{} = format, locale, calendar, backend, options) do
    %{number_system: number_system, format: format} = format

    {:ok, format_string, options} =
      find_format(datetime, format, locale, calendar, backend, options)

    {:ok, %{number_system: number_system, format: format_string}, options}
  end

  # If its a partial datetime and a standard format is requested, its an error
  defp find_format(datetime, format, _locale, _calendar, _backend, _options)
       when format in @format_types and not is_any_date_time(datetime) do
    {:error,
     {
       Cldr.DateTime.UnresolvedFormat,
       "Standard formats are not available for partial date times"
     }}
  end

  # We need to derive the format, or maybe even date_format and time_format
  defp find_format(datetime, nil, locale, calendar, backend, options) do
    date_format = options.date_format
    time_format = options.time_format

    with {:ok, date_format} <- date_format(datetime, date_format, locale, calendar, backend),
         {:ok, time_format} <- time_format(datetime, time_format, locale, calendar, backend),
         {:ok, format} <- resolve_format(date_format, locale, calendar, backend) do
      options =
        options
        |> Map.put(:date_format, date_format)
        |> Map.put(:time_format, time_format)

      {:ok, format, options}
    end
  end

  # From https://www.unicode.org/reports/tr35/tr35-dates.html#Missing_Skeleton_Fields
  # Combine the patterns for the two dateFormatItems using the appropriate dateTimeFormat pattern, determined as follows from the requested date
  # fields:
  #  If the requested date fields include wide month (MMMM, LLLL) and weekday name of any length (e.g. E, EEEE, c, cccc), use <dateTimeFormatLength
  #  type="full">
  #  Otherwise, if the requested date fields include wide month, use <dateTimeFormatLength type="long">
  #  Otherwise, if the requested date fields include abbreviated month (MMM, LLL), use <dateTimeFormatLength type="medium">
  #  Otherwise use <dateTimeFormatLength type="short">

  defp resolve_format(date_format, locale, calendar, backend) do
    {:ok, formats} = Cldr.DateTime.Format.date_time_formats(locale, calendar, backend)

    cond do
      has_wide_month?(date_format) && has_weekday_name?(date_format) ->
        {:ok, formats.full}

      has_wide_month?(date_format) ->
        {:ok, formats.long}

      has_abbreviated_month?(date_format) ->
        {:ok, formats.medium}

      true ->
        {:ok, formats.short}
    end
  end

  # We need to derive the date format now since that data
  # is used to establish what datetime format we derive.

  defp date_format(datetime, nil, locale, calendar, backend) do
    format = Cldr.Date.derive_format_id(datetime)
    Cldr.Date.find_format(datetime, format, locale, calendar, backend)
  end

  defp date_format(datetime, format, locale, calendar, backend) do
    Cldr.Date.find_format(datetime, format, locale, calendar, backend)
  end

  defp time_format(datetime, nil, locale, calendar, backend) do
    format = Cldr.Time.derive_format_id(datetime)
    Cldr.Time.find_format(datetime, format, locale, calendar, backend)
  end

  defp time_format(datetime, format, locale, calendar, backend) do
    Cldr.Time.find_format(datetime, format, locale, calendar, backend)
  end

  # FIXME These functions don't consider the impace
  # of literals in the format. For now, the only known
  # literal is a "," or "at" so we are safe for the moment.

  defp has_wide_month?(format) do
    String.contains?(format, "MMMM") || String.contains?(format, "LLLL")
  end

  defp has_abbreviated_month?(format) do
    String.contains?(format, "MMM") || String.contains?(format, "LLL")
  end

  defp has_weekday_name?(format) do
    String.contains?(format, "E") || String.contains?(format, "c")
  end

  # Given the fields in the (maybe partial) date, derive
  # format id (atom map key into available formats)

  @doc false
  def derive_format_id(datetime, field_map, field_names) do
    datetime
    |> Map.take(field_names)
    |> Map.keys()
    |> Enum.map(&Map.fetch!(field_map, &1))
    |> Enum.join()
    |> String.to_atom()
  end

  defp preferred_format(formats, format, prefer) do
    case Map.fetch(formats, format) do
      {:ok, format} ->
        apply_preference(format, prefer)

      :error ->
        {:error,
         {Cldr.DateTime.InvalidFormat,
          "Invalid datetime format #{inspect(format)}. " <>
            "The valid formats are #{inspect(formats)}."}}
    end
  end

  @doc false
  def apply_preference(%{unicode: unicode, ascii: ascii}, preference) do
    if :ascii in preference do
      {:ok, ascii}
    else
      {:ok, unicode}
    end
  end

  def apply_preference(%{default: default, variant: variant}, preference) do
    if :variant in preference do
      {:ok, variant}
    else
      {:ok, default}
    end
  end

  def apply_preference(format, _) do
    {:ok, format}
  end

  @doc false
  def resolve_plural_format(%{other: _, pluralize: field} = format, date_time, backend, options) do
    pluralizer = Module.concat(backend, Number.Cardinal)

    case apply(Cldr.Calendar, field, [date_time]) do
      {_year_or_month, month_or_week} ->
        {:ok, pluralizer.pluralize(month_or_week, options.locale, format)}

      other ->
        {:ok, pluralizer.pluralize(other, options.locale, format)}
    end
  end

  def resolve_plural_format(format, _date_time, _backend, _options) do
    {:ok, format}
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Invalid DateTime. DateTime is a map that contains at least #{requirements}. " <>
        "Found: #{inspect(map)}"}}
  end
end
