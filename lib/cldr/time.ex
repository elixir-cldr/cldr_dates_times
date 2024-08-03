defmodule Cldr.Time do
  @moduledoc """
  Provides localization and formatting of a time.

  A time is any `t:Time.t/0` struct or any map with one or more of
  the keys `:hour`, `:minute`, `:second` and optionally `:time_zone`,
  `:zone_abbr`, `:utc_offset`, `:std_offset` and `:microsecond`.

  `Cldr.Time` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  CLDR provides standard format strings for `Time` which
  are represented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale may define the underlying
  format string as appropriate.

  """

  alias Cldr.LanguageTag
  alias Cldr.Locale

  import Cldr.DateTime,
    only: [resolve_plural_format: 4, apply_preference: 2, has_time: 1]

  @typep options :: Keyword.t() | map()

  @format_types [:short, :medium, :long, :full]
  @default_format_type :medium
  @default_prefer :unicode

  @field_map %{
    hour: "h",
    minute: "m",
    second: "s",
    time_zone: "v",
    zone_abbr: "V"
  }

  @field_names Map.keys(@field_map)

  # TODO Do we need microseconds here too? Are there any standard formats that use it?
  # have we got the formatting right for fractional seconds?
  # have we got derived formats working for microseconds?

  defguard is_full_time(time)
           when is_map_key(time, :hour) and is_map_key(time, :minute) and is_map_key(time, :second)

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.Time, :format_types)
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ### Returns

  * `{:ok, formatted_time}` or

  * `{:error, reason}`.

  ### Arguments

  * `time` is a `t:Time.t/0` struct or any map that contains
    one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
    `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ### Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
    or a format string. The default is `:medium` for full times (that is,
    times having `:hour`, `:minute` and `:second` fields). The
    default for partial times is to derive a candidate format from the time and
    find the best match from the formats returned by
    `Cldr.Time.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

  * `:locale` any locale returned by `Cldr.known_locale_names/1`.  The default is
    `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted date digits should
    be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

  * `period: :variant` will use a variant for the time period and flexible time period if
    one is available in the locale.  For example, in the `:en` locale, `period: :variant` will
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

  ### Examples

      iex> Cldr.Time.to_string(~T[07:35:13.215217], MyApp.Cldr)
      {:ok, "7:35:13 AM"}

      iex> Cldr.Time.to_string(~T[07:35:13.215217], MyApp.Cldr, format: :short)
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string(~T[07:35:13.215217], MyApp.Cldr, format: :short, period: :variant)
      {:ok, "7:35 am"}

      iex> Cldr.Time.to_string(~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr")
      {:ok, "07:35:13"}

      iex> Cldr.Time.to_string(~T[07:35:13.215217], MyApp.Cldr, format: :medium)
      {:ok, "7:35:13 AM"}

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string datetime, MyApp.Cldr, format: :long
      {:ok, "11:59:59 PM UTC"}

      # A partial time with a best match CLDR-defined format
      iex> Cldr.Time.to_string(%{hour: 23, minute: 11})
      {:ok, "11:11 PM"}

      # Sometimes the available time fields can't be mapped to an available
      # CLDR-defined format.
      iex> Cldr.Time.to_string(%{minute: 11})
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :m"}}

  """
  @spec to_string(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  @spec to_string(Cldr.Calendar.any_date_time(), options(), []) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = time, backend, options) do
    %{time | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(time, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(time, backend, options)
  end

  def to_string(%{} = time, backend, options)
      when is_atom(backend) and has_time(time) do
    options = normalize_options(time, backend, options)
    format_backend = Module.concat(backend, DateTime.Formatter)

    calendar = Map.get(time, :calendar, Cldr.Calendar.Gregorian)
    time = Map.put_new(time, :calendar, calendar)
    number_system = Map.get(options, :number_system)

    locale = options.locale
    format = options.format
    prefer = List.wrap(options.prefer)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         {:ok, format} <- find_format(time, format, locale, cldr_calendar, backend),
         {:ok, format} <- apply_preference(format, prefer),
         {:ok, format_string} <- resolve_plural_format(format, time, backend, options) do
      format_backend.format(time, format_string, locale, options)
    end
  rescue
    e in [Cldr.DateTime.FormatError] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(time, value, []) when is_map(time) do
    {:error, {ArgumentError, "Unexpected option value #{inspect value}. Options must be a keyword list"}}
  end

  def to_string(time, _backend, _options) do
    error_return(time, [:hour, :minute, :second])
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ### Arguments

  * `time` is a `t:Time.t/0` struct or any map that contains
    one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
    `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ### Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
    or a format string. The default is `:medium` for full times (that is,
    times having `:hour`, `:minute` and `:second` fields). The
    default for partial times is to derive a candidate format from the time and
    find the best match from the formats returned by
    `Cldr.Time.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted time digits should
    be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

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

  ### Returns

  * `formatted_time_string` or

  * raises an exception.

  ### Examples

      iex> Cldr.Time.to_string!(~T[07:35:13.215217], MyApp.Cldr)
      "7:35:13 AM"

      iex> Cldr.Time.to_string!(~T[07:35:13.215217], MyApp.Cldr, format: :short)
      "7:35 AM"

      iex> Cldr.Time.to_string!(~T[07:35:13.215217], MyApp.Cldr, format: :short, period: :variant)
      "7:35 am"

      iex> Cldr.Time.to_string!(~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr")
      "07:35:13"

      iex> Cldr.Time.to_string!(~T[07:35:13.215217], MyApp.Cldr, format: :medium)
      "7:35:13 AM"

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string!(datetime, MyApp.Cldr, format: :long)
      "11:59:59 PM UTC"

      # A partial time with a best match CLDR-defined format
      iex> Cldr.Time.to_string!(%{hour: 23, minute: 11})
      "11:11 PM"

  """
  @spec to_string!(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          String.t() | no_return()

  @spec to_string!(Cldr.Calendar.any_date_time(), options(), []) ::
          String.t() | no_return()

  def to_string!(time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(time, backend, options) do
    case to_string(time, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  # TODO deprecate :style in version 3.0
  defp normalize_options(_time, _backend, %{} = options) do
    options
  end

  defp normalize_options(time, backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    default_prefer = List.wrap(@default_prefer)
    format = format_from_options(time, nil, @default_format_type, default_prefer)

    %{locale: locale, number_system: number_system, format: format, prefer: default_prefer}
  end

  defp normalize_options(time, backend, options) do
    {locale, _backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)
    prefer = Keyword.get(options, :prefer, @default_prefer) |> List.wrap()
    format_option = options[:time_format] || options[:format] || options[:style]
    format = format_from_options(time, format_option, @default_format_type, prefer)

    options
    |> Map.new()
    |> Map.put(:locale, locale)
    |> Map.put(:format, format)
    |> Map.put(:prefer, prefer)
    |> Map.delete(:style)
    |> Map.put_new(:number_system, number_system)
  end

  # Full date, no option, use the default format
  defp format_from_options(time, nil, default_format, _prefer) when is_full_time(time) do
    default_format
  end

  # Partial date, no option, derive the format from the date
  defp format_from_options(time, nil, _default_format, _prefer) do
    derive_format_id(time)
  end

  # If a format is requested, use it
  defp format_from_options(_time, format, _default_format, prefer) do
    {:ok, format} = apply_preference(format, prefer)
    format
  end

  @doc false
  def derive_format_id(time) do
    Cldr.DateTime.derive_format_id(time, @field_map, @field_names)
  end

  # If its a full time we can use one of the standard formats (:short, :medium, :long)
  # and if its a full date and no format is specified then the default :medium will be
  # applied.
  @doc false
  def find_format(time, format, locale, calendar, backend)
      when format in @format_types and is_full_time(time) do
    %LanguageTag{cldr_locale_name: locale_name} = locale

    with {:ok, time_formats} <- formats(locale_name, calendar, backend) do
      {:ok, Map.fetch!(time_formats, format)}
    end
  end

  # If its a partial date and a standard format is requested, its an error

  def find_format(time, format, _locale, _calendar, _backend)
      when format in @format_types and not is_full_time(time) do
    {:error,
     {
       Cldr.DateTime.UnresolvedFormat,
       "Standard formats are not accepted for partial times"
     }}
  end

  def find_format(time, %{format: format} = format_map, locale, calendar, backend) do
    %{number_system: number_system} = format_map
    {:ok, format_string} = find_format(time, format, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  # If its an atom format it means we want to use one of the available formats. Since
  # these are map keys they can be used in a locale-independent way. If the requested
  # format is a direct match, use it. If not - try to find the best match between the
  # requested format and available formats.

  def find_format(_time, format, locale, calendar, backend) when is_atom(format) do
    {:ok, available_formats} = available_formats(locale, calendar, backend)

    if Map.has_key?(available_formats, format) do
      Map.fetch(available_formats, format)
    else
      resolve_format(format, available_formats, locale, calendar, backend)
    end
  end

  # If its a binary then its considered a format string so we use
  # it directly.

  def find_format(_time, format_string, _locale, _calendar, _backend)
      when is_binary(format_string) do
    {:ok, format_string}
  end

  @doc false
  defdelegate resolve_format(format, available_formats, locale, calendar, backend), to: Cldr.Date

  @doc """
  Returns a map of the standard time formats for a given
  locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.Time.formats(:en, :gregorian, MyApp.Cldr)
      {:ok,
       %Cldr.Time.Formats{
         short: "h:mm a",
         medium: "h:mm:ss a",
         long: "h:mm:ss a z",
         full: "h:mm:ss a zzzz"
       }}

      iex> Cldr.Time.formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
       %Cldr.Time.Formats{
         short: "h:mm a",
         medium: "h:mm:ss a",
         long: "h:mm:ss a z",
         full: "h:mm:ss a zzzz"
       }}

  """
  @spec formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, Cldr.DateTime.Format.standard_formats()} | {:error, {atom, String.t()}}

  def formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    Cldr.DateTime.Format.time_formats(locale, calendar, backend)
  end

  @doc """
  Returns a map of the available date formats for a
  given locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.Time.available_formats(:en)
      {:ok,
       %{
         h: %{unicode: "h a", ascii: "h a"},
         hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         ms: "mm:ss",
         H: "HH",
         Hm: "HH:mm",
         Hms: "HH:mm:ss",
         Hmsv: "HH:mm:ss v",
         Hmv: "HH:mm v",
         hm: %{unicode: "h:mm a", ascii: "h:mm a"},
         hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
         hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"}
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
    backend = Module.concat(backend, DateTime.Format)
    backend.time_available_formats(locale, calendar)
  end

  @doc """
  Return the preferred time format for a locale.

  ### Arguments

  * `language_tag` is any language tag returned by `Cldr.Locale.new/2`
    or any `locale_name` returned by `Cldr.known_locale_names/1`

  ### Returns

  * The hour format as an atom to be used for localization purposes. The
    return value is used as a function name in `Cldr.DateTime.Formatter`

  ### Notes

  * The `hc` key of the `u` extension is honoured and will
    override the default preferences for a locale or territory.
    See the last example below.

  * Different locales and territories present the hour
    of day in different ways. These are represented
    in `Cldr.DateTime.Formatter` in the following way:

  | Symbol  | Midn.  |  Morning  | Noon  |  Afternoon | Midn. |
  | :----:  | :---:  | :-----:   | :--:  | :--------: | :---: |
  |   h     |  12    | 1...11    |  12   |   1...11   |  12   |
  |   K     |   0    | 1...11    |   0   |   1...11   |   0   |
  |   H     |   0    | 1...11    |  12   |  13...23   |   0   |
  |   k     |  24    | 1...11    |  12   |  13...23   |  24   |

  ### Examples

      iex> Cldr.Time.hour_format_from_locale("en-AU")
      :h12

      iex> Cldr.Time.hour_format_from_locale("fr")
      :h23

      iex> Cldr.Time.hour_format_from_locale("fr-u-hc-h12")
      :h12

  """
  def hour_format_from_locale(%LanguageTag{locale: %{hc: hour_cycle}})
      when not is_nil(hour_cycle) do
    hour_cycle
  end

  def hour_format_from_locale(%LanguageTag{} = locale) do
    preferences = time_preferences()
    territory = Cldr.Locale.territory_from_locale(locale)

    preference =
      preferences[locale.cldr_locale_name] ||
        preferences[territory] ||
        preferences[Cldr.the_world()]

    Map.fetch!(time_symbols(), preference.preferred)
  end

  def hour_format_from_locale(locale_name, backend \\ Cldr.Date.default_backend()) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      hour_format_from_locale(locale)
    end
  end

  @doc false
  @time_preferences Cldr.Config.time_preferences()
  def time_preferences do
    @time_preferences
  end

  # | Symbol   | Midn.  |  Morning  | Noon  | Afternoon  | Midn. | Code
  # | :----:   | :---:  | :-----:   | :--:  | :--------: | :---: | :--:
  # |   h      |  12    | 1...11    |  12   |   1...11   |  12   | :h12
  # |   K      |   0    | 1...11    |   0   |   1...11   |   0   | :h11
  # |   H      |   0    | 1...11    |  12   |  13...23   |   0   | :h23
  # |   k      |  24    | 1...11    |  12   |  13...23   |  24   | :h24
  #
  defp time_symbols do
    %{
      # :hour_1_12,
      "h" => :h12,
      # :hour_0_11,
      "K" => :h11,
      # :hour_0_23,
      "H" => :h23,
      # :hour_1_24.
      "k" => :h24
    }
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Invalid time. Time is a map that contains at least #{requirements} fields. " <>
        "Found: #{inspect(map)}"}}
  end
end
