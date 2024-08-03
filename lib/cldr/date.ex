defmodule Cldr.Date do
  @moduledoc """
  Provides localization and formatting of a `t:Date.t/0`
  struct or any map with one or more of the keys `:year`, `:month`,
  `:day` and optionally `:calendar`.

  `Cldr.Date` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars).

  CLDR provides standard format strings for `t:Date.t/0` which
  are represented by the formats `:short`, `:medium`, `:long`
  and `:full`.  This abstraction allows for locale-independent
  formatting since each locale and calendar may define the underlying
  format string as appropriate.

  """

  alias Cldr.LanguageTag
  alias Cldr.Locale

  import Cldr.DateTime,
    only: [resolve_plural_format: 4, apply_preference: 2, has_date: 1]

  @typep options :: Keyword.t() | map()

  @format_types [:short, :medium, :long, :full]
  @default_format_type :medium
  @default_prefer :unicode

  @field_map %{
    year: "y",
    month: "M",
    day: "d"
  }

  @field_names Map.keys(@field_map)

  defguard is_full_date(date)
           when is_map_key(date, :year) and is_map_key(date, :month) and is_map_key(date, :day)

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.Date, :format_types)
  end

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ### Arguments

  * `date` is a `t:Date.t/0` struct or any map that contains one or more
    of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ### Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format ID
    or a format string. The default is `:medium` for full dates (that is,
    dates having `:year`, `:month`, `:day` and `:calendar` fields). The
    default for partial dates is to derive a candidate format ID from the date and
    find the best match from the formats returned by
    `Cldr.Date.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

  * `:locale` any locale returned by `Cldr.known_locale_names/1`.
    The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted date digits
    should be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

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

  * `{:ok, formatted_string}` or

  * `{:error, reason}`

  ### Examples

      # Full dates have the default format `:medium`
      iex> Cldr.Date.to_string(~D[2017-07-10], MyApp.Cldr, locale: :en)
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string(~D[2017-07-10], MyApp.Cldr, format: :medium, locale: :en)
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string(~D[2017-07-10], MyApp.Cldr, format: :full, locale: :en)
      {:ok, "Monday, July 10, 2017"}

      iex> Cldr.Date.to_string(~D[2017-07-10], MyApp.Cldr, format: :short, locale: :en)
      {:ok, "7/10/17"}

      iex> Cldr.Date.to_string(~D[2017-07-10], MyApp.Cldr, format: :short, locale: "fr")
      {:ok, "10/07/2017"}

      iex> Cldr.Date.to_string(~D[2024-03-01], format: :yMd, prefer: :variant, locale: "en-CA")
      {:ok, "1/3/2024"}

      # A partial date with a derived "best match" format
      iex> Cldr.Date.to_string(%{year: 2024, month: 6}, MyApp.Cldr, locale: "fr")
      {:ok, "06/2024"}

      # A partial date with a best match CLDR-defined format
      iex> Cldr.Date.to_string(%{year: 2024, month: 6}, MyApp.Cldr, format: :yMMM, locale: "fr")
      {:ok, "juin 2024"}

      # Sometimes the available date fields can't be mapped to an available
      # CLDR-defined format.
      iex> Cldr.Date.to_string(%{year: 2024, day: 3}, MyApp.Cldr, locale: "fr")
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :dy"}}

  """
  @spec to_string(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  @spec to_string(Cldr.Calendar.any_date_time(), options(), []) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(date, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = date, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(date, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(date, backend, options)
  end

  def to_string(%{} = date, backend, options)
      when is_atom(backend) and has_date(date) do
    options = normalize_options(date, backend, options)
    format_backend = Module.concat(backend, DateTime.Formatter)

    calendar = Map.get(date, :calendar, Cldr.Calendar.Gregorian)
    date = Map.put_new(date, :calendar, calendar)
    number_system = Map.get(options, :number_system)

    locale = options.locale
    format = options.format
    prefer = List.wrap(options.prefer)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         {:ok, format} <- find_format(date, format, locale, cldr_calendar, backend),
         {:ok, format} <- apply_preference(format, prefer),
         {:ok, format_string} <- resolve_plural_format(format, date, backend, options) do
      format_backend.format(date, format_string, locale, options)
    end
  rescue
    e in [Cldr.DateTime.FormatError] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(date, value, []) when is_map(date) do
    {:error, {ArgumentError, "Unexpected option value #{inspect value}. Options must be a keyword list"}}
  end

  def to_string(date, _backend, _options) do
    error_return(date, [:year, :month, :day, :calendar])
  end

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
  or raises an exception.

  ### Arguments

  * `date` is a `t:Date.t/0` struct or any map that contains one or more
    of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ### Options

  * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format ID
    or a format string. The default is `:medium` for full dates (that is,
    dates having `:year`, `:month`, `:day` and `:calendar` fields). The
    default for partial dates is to derive a candidate format from the date and
    find the best match from the formats returned by
    `Cldr.Date.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
    for more information about specifying formats.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted date digits should
    be transliterated.

  * `:prefer` expresses the preference for one of the possible alternative
    sub-formats. See the variant preference notes below.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

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

  * `formatted_date` or

  * raises an exception.

  ### Examples

      iex> Cldr.Date.to_string!(~D[2017-07-10], MyApp.Cldr, locale: :en)
      "Jul 10, 2017"

      iex> Cldr.Date.to_string!(~D[2017-07-10], MyApp.Cldr, format: :medium, locale: :en)
      "Jul 10, 2017"

      iex> Cldr.Date.to_string!(~D[2017-07-10], MyApp.Cldr, format: :full, locale: :en)
      "Monday, July 10, 2017"

      iex> Cldr.Date.to_string!(~D[2017-07-10], MyApp.Cldr, format: :short, locale: :en)
      "7/10/17"

      iex> Cldr.Date.to_string!(~D[2017-07-10], MyApp.Cldr, format: :short, locale: "fr")
      "10/07/2017"

      iex> Cldr.Date.to_string!(~D[2024-03-01], format: :yMd, prefer: :variant, locale: "en-CA")
      "1/3/2024"

      # A partial date with a derived "best match" format
      iex> Cldr.Date.to_string!(%{year: 2024, month: 6}, MyApp.Cldr, locale: "fr")
      "06/2024"

      # A partial date with a best match CLDR-defined format
      iex> Cldr.Date.to_string!(%{year: 2024, month: 6}, MyApp.Cldr, format: :yMMM, locale: "fr")
      "juin 2024"

  """
  @spec to_string!(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          String.t() | no_return()

  @spec to_string!(Cldr.Calendar.any_date_time(), options(), []) ::
          String.t() | no_return()

  def to_string!(date, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(date, backend, options) do
    case to_string(date, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  # TODO deprecate :style in version 3.0
  defp normalize_options(_date, _backend, %{} = options) do
    options
  end

  defp normalize_options(date, backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    prefer = List.wrap(@default_prefer)
    format = format_from_options(date, nil, @default_format_type, prefer)

    %{locale: locale, number_system: number_system, format: format, prefer: prefer}
  end

  defp normalize_options(date, backend, options) when is_list(options) do
    {locale, _backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)
    prefer = Keyword.get(options, :prefer, @default_prefer) |> List.wrap()
    format_option = options[:date_format] || options[:format] || options[:style]
    format = format_from_options(date, format_option, @default_format_type, prefer)

    options
    |> Map.new()
    |> Map.put(:locale, locale)
    |> Map.put(:format, format)
    |> Map.put(:prefer, prefer)
    |> Map.delete(:style)
    |> Map.put_new(:number_system, number_system)
  end

  # Full date, no option, use the default format
  defp format_from_options(date, nil, default_format, _prefer) when is_full_date(date) do
    default_format
  end

  # Partial date, no option, derive the format from the date
  defp format_from_options(date, nil, _default_format, _prefer) do
    derive_format_id(date)
  end

  # If a format is requested, use it
  defp format_from_options(_time, format, _default_format, prefer) do
    {:ok, format} = apply_preference(format, prefer)
    format
  end

  @doc false
  def derive_format_id(date) do
    Cldr.DateTime.derive_format_id(date, @field_map, @field_names)
  end

  @doc """
  Returns a map of the standard date formats for a given
  locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.Date.formats(:en, :gregorian, MyApp.Cldr)
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y",
        long: "MMMM d, y",
        medium: "MMM d, y",
        short: "M/d/yy"
      }}

      iex> Cldr.Date.formats(:en, :buddhist, MyApp.Cldr)
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y G",
        long: "MMMM d, y G",
        medium: "MMM d, y G",
        short: "M/d/y GGGGG"
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
    Cldr.DateTime.Format.date_formats(locale, calendar, backend)
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

      iex> Cldr.Date.available_formats(:en)
      {:ok,
       %{
         d: "d",
         y: "y",
         E: "ccc",
         M: "L",
         MMMEd: "E, MMM d",
         Ed: "d E",
         Md: "M/d",
         GyMMMd: "MMM d, y G",
         Gy: "y G",
         GyMMM: "MMM y G",
         GyMMMEd: "E, MMM d, y G",
         MMMd: "MMM d",
         GyMd: "M/d/y G",
         MMMMd: "MMMM d",
         MEd: "E, M/d",
         MMM: "LLL",
         yMd: "M/d/y",
         yMMMd: "MMM d, y",
         yMMMM: "MMMM y",
         yMMM: "MMM y",
         yMMMEd: "E, MMM d, y",
         yMEd: "E, M/d/y",
         yM: "M/y",
         yQQQQ: "QQQQ y",
         yQQQ: "QQQ y",
         yw: %{
           other: "'week' w 'of' Y",
           pluralize: :week_of_year,
           one: "'week' w 'of' Y"
         },
         MMMMW: %{
           other: "'week' W 'of' MMMM",
           pluralize: :week_of_month,
           one: "'week' W 'of' MMMM"
         }
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
    backend.date_available_formats(locale, calendar)
  end

  # If its a full date we can use one of the standard formats (:short, :medium, :long)
  # and if its a full date and no format is specified then the default :medium will be
  # applied.
  @doc false
  def find_format(date, format, locale, calendar, backend)
      when format in @format_types and is_full_date(date) do
    %LanguageTag{cldr_locale_name: locale_name} = locale

    with {:ok, date_formats} <- formats(locale_name, calendar, backend) do
      {:ok, Map.fetch!(date_formats, format)}
    end
  end

  # If its a partial date and a standard format is requested, its an error

  def find_format(date, format, _locale, _calendar, _backend)
      when format in @format_types and not is_full_date(date) do
    {:error,
     {
       Cldr.DateTime.UnresolvedFormat,
       "Standard formats are not accepted for partial dates"
     }}
  end

  def find_format(date, %{} = format_map, locale, calendar, backend) do
    %{number_system: number_system, format: format} = format_map
    {:ok, format_string} = find_format(date, format, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  # If its an atom format it means we want to use one of the available formats. Since
  # these are map keys they can be used in a locale-independent way. If the requested
  # format is a direct match, use it. If not - try to find the best match between the
  # requested format and available formats.

  def find_format(_date, format, locale, calendar, backend) when is_atom(format) do
    {:ok, available_formats} = available_formats(locale, calendar, backend)

    if Map.has_key?(available_formats, format) do
      Map.fetch(available_formats, format)
    else
      resolve_format(format, available_formats, locale, calendar, backend)
    end
  end

  # If its a binary then its considered a format string so we use
  # it directly.

  def find_format(_date, format_string, _locale, _calendar, _backend)
      when is_binary(format_string) do
    {:ok, format_string}
  end

  @doc false
  def resolve_format(format, available_formats, locale, calendar, backend) do
    with {:ok, match} <- Cldr.DateTime.Format.best_match(format, locale, calendar, backend),
         {:ok, format} <- Map.fetch(available_formats, match) do
      {:ok, format}
    else
      :error ->
        {:error, Cldr.DateTime.Format.no_format_resolved_error(format)}

      other ->
        other
    end
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Missing required date fields. The function requires a map with at least #{requirements}. " <>
        "Found: #{inspect(map)}"}}
  end

  @doc false
  # TODO remove for Cldr 3.0
  if Code.ensure_loaded?(Cldr) && function_exported?(Cldr, :default_backend!, 0) do
    def default_backend do
      Cldr.default_backend!()
    end
  else
    def default_backend do
      Cldr.default_backend()
    end
  end
end
