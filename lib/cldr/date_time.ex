defmodule Cldr.DateTime do
  @moduledoc """
  Provides localized formatting of full or partial date_times.

  A date_time is any `t:DateTime.t/0` or `t:NaiveDateTime.t/0`
  struct or any map that contains one or more of the keys `:year`, `:month`, `:day`,
  `:hour`, `:minute` and `:second` or `:microsecond` with optional `:time_zone`, `:zone_abbr`,
  `:utc_offset`, `:std_offset` and `:calendar` fields.

  `Cldr.DateTime` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  For information about specifying formats, see `Cldr.DateTime.Format`.

  """

  alias Cldr.DateTime.Format.Compiler
  alias Cldr.DateTime.Format.Match
  alias Cldr.DateTime.Format
  alias Cldr.Locale

  @typep options :: Keyword.t() | map()

  @standard_formats Format.standard_formats()
  @default_standard_format :medium
  @default_style :default
  @default_prefer :unicode
  @default_separators :standard

  @doc """
  Indicates if a given map fulfills the requirements
  for a naive date time.
  """
  defguard is_naive_date_time(date_time)
           when is_map_key(date_time, :year) and
                  is_map_key(date_time, :month) and
                  is_map_key(date_time, :day) and
                  is_map_key(date_time, :hour) and
                  is_map_key(date_time, :minute) and
                  is_map_key(date_time, :second)

  @doc """
  Indicates if a given map fulfills the requirements
  for a date time.
  """
  defguard is_date_time(date_time)
           when is_naive_date_time(date_time) and
                  is_map_key(date_time, :time_zone) and
                  is_map_key(date_time, :zone_abbr)

  @doc """
  Indicates if a given map fulfills the requirements
  for a naive date time or date time.
  """
  defguard is_any_date_time(date_time)
           when is_date_time(date_time) or is_naive_date_time(date_time)

  @doc """
  Guards whether the given date_time has components of
  a date.
  """
  defguard has_date(date_time)
           when is_map_key(date_time, :year) or is_map_key(date_time, :month) or
                  is_map_key(date_time, :day)

  @doc """
  Guards whether the given date_time has components of
  a time.
  """
  defguard has_time(date_time)
           when is_map_key(date_time, :hour) or is_map_key(date_time, :minute) or
                  is_map_key(date_time, :second)

  @doc """
  Guard whether the given date_time has components of
  both a date and a time.
  """
  defguard has_date_and_time(date_time)
           when has_date(date_time) and has_time(date_time)

  @doc """
  Guard whether a format is a format skeleton
  """
  defguard is_skeleton(format) when is_atom(format) and not is_nil(format)

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.DateTime, :standard_formats)
  end

  @doc """
  Formats a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` according to the formats
  defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ### Arguments

  * `date_time` is a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
    `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
    and `:calendar` fields.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

  * `:format` is either a [standard format](Cldr.DateTime.Format.html#module-standard-formats)
    (one of `:short`, `:medium`, `:long`, `:full`), a [format skeleton](Cldr.DateTime.Format.html#module-format-skeletons)
    or a [format pattern](Cldr.DateTime.Format.html#module-format-patterns).

    * The default is `:medium` for full *date_times* (that is, *dates_times* having `:year`,
      `:month`, `:day`, `:hour`, `:minutes`, `:second` and `:calendar` fields).

    * The default for partial *date_times* is to derive a format skeleton from the
      *date_time* and find the best match from the formats returned by
      `Cldr.DateTime.available_formats/3`.

    * See `Cldr.DateTime.Format` for more information about specifying formats.

  * `:date_format` is used to format the *date* part of a *date_time* and is either a standard
    format or a format skeleton.

    * If `:date_format` is not specified then the *date* format is defined by the `:format`
      option.

    * If `:date_format` is a format skeleton it may only include format fields
      appropriate for a *date*.

    * :date_format` may only be specified if `:format` is a standard format.

  * `:time_format` is used to format the *time* part of a *date_time* and is either a standard
    format or a format skeleton.

    * If `:time_format` is not specified then the *time* format is defined by the `:format`
      option.

    * If `:time_format` is a format skeleton it may only include format fields
      appropriate for a *time*.

    * :time_format` may only be specified if `:format` is a standard format.

  * `:style` is either `:at` or `:default`. When set to `:at` the *date_time* may
    be formatted with a localised string representing `<date> at <time>` if such
    a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

  * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
    formats have two variants - one using Unicode spaces (typically non-breaking space) and
    another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
    use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
    to see which formats have these variants. See [Variant Preference](#variant-preference)
    below for more information.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted *date_time* digits should
    be transliterated. See `Cldr.known_number_systems/0`. The default is
    the number system associated with the `:locale`.

  * `:separators` selects which of the available symbol
    sets should be used when formatting fractional seconds (format
    character `S`).  The default is `:standard`. Some limited locales have an alternative `:us`
    variant that can be used. See `Cldr.Number.Symbol.number_symbols_for/3`
    for the symbols supported for a given locale and number system.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

  * `:period` which, if set to `:variant`, will use a variant for the time period and flexible
    time period if one is available in the locale.  For example, in the `:en` locale
    `period: :variant` will return "pm" instead of "PM".

  ### Variant Preference

  * A small number of formats have one of two different alternatives, each with their own
    preference specifier. The preferences are specified with the `:prefer` option to
    `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
    atoms with one atom being either `:unicode` or `:ascii` and one atom being either
    `:default` or `:variant`.

    * Some formats (at the time of publishng only *time* formats but that
      may change in the future) have `:unicode` and `:ascii` versions of the format. The
      difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
      whereas the `:unicode` version may use non-breaking or other space characters. The
      default is `:unicode` and this is the strongly preferred option. The `:ascii` format
      is primarily to support legacy use cases and is not recommended. See
      `Cldr.Time.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only *date* and *date_time* formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Notes

  * If the provided `date_time` contains only *date* fields, the call is delegated to
    `Cldr.Date.to_string/2`.

  * If the provided `date_time` contains only *time* fields, the call is delegated to
    `Cldr.Time.to_string/2`.

  ### Returns

  * `{:ok, formatted_date_time}` or

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
      {:ok, "Saturday, January 1, 2000, 11:59:59 PM Coordinated Universal Time"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, locale: :fr)
      {:ok, "samedi 1 janvier 2000, 23:59:59 temps universel coordonné"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :en)
      {:ok, "Saturday, January 1, 2000 at 11:59:59 PM Coordinated Universal Time"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :fr)
      {:ok, "samedi 1 janvier 2000 à 23:59:59 temps universel coordonné"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      {:ok, "semaine 1 (janvier)"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      {:ok, "semaine 1 de 2000"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, date_format: :yMd, time_format: :hms)
      {:ok, "1/1/2000, 11:59:59 PM"}

  """
  @spec to_string(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  @spec to_string(Cldr.Calendar.any_date_time(), options(), []) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(date_time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = date_time, backend, options) do
    %{date_time | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(date_time, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(date_time, backend, options)
  end

  def to_string(%{} = date_time, backend, options)
      when is_atom(backend) and has_date_and_time(date_time) do
    format_backend = Module.concat(backend, DateTime.Formatter)

    with {:ok, date_time, options} <- normalize_options(date_time, backend, options),
         {:ok, locale} <- Cldr.validate_locale(options.locale, backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(date_time.calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, options.number_system, backend),
         {:ok, format, options} <-
           find_format(date_time, options.format, locale, cldr_calendar, backend, options),
         {:ok, format} <- apply_preference(format, options.prefer),
         {:ok, format_string} <- resolve_plural_format(format, date_time, backend, options) do
      format_backend.format(date_time, format_string, locale, options)
    end
  rescue
    e in [Cldr.DateTime.FormatError] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(%{} = date_time, backend, options)
      when is_atom(backend) and has_date(date_time) do
    Cldr.Date.to_string(date_time, backend, options)
  end

  def to_string(%{} = date_time, backend, options)
      when is_atom(backend) and has_time(date_time) do
    Cldr.Time.to_string(date_time, backend, options)
  end

  def to_string(date_time, value, []) when is_map(date_time) do
    {:error,
     {ArgumentError, "Unexpected option value #{inspect(value)}. Options must be a keyword list"}}
  end

  def to_string(date_time, _backend, _options) do
    error_return(date_time, [:year, :month, :day, :hour, :minute, :second, :calendar])
  end

  @doc """
  Formats a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` according to the formats
  defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
  or raises on error.

  ### Arguments

  * `date_time` is a `t:DateTime.t/0` or `t:NaiveDateTime.t/0` struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
    `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
    and `:calendar` fields.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

  * `:format` is either a [standard format](Cldr.DateTime.Format.html#module-standard-formats)
    (one of `:short`, `:medium`, `:long`, `:full`), a [format skeleton](Cldr.DateTime.Format.html#module-format-skeletons)
    or a [format pattern](Cldr.DateTime.Format.html#module-format-patterns).

    * The default is `:medium` for full *date_times* (that is, *dates_times* having `:year`,
      `:month`, `:day`, `:hour`, `:minutes`, `:second` and `:calendar` fields).

    * The default for partial *date_times* is to derive a format skeleton from the
      *date_time* and find the best match from the formats returned by
      `Cldr.DateTime.available_formats/3`.

    * See `Cldr.DateTime.Format` for more information about specifying formats.

  * `:date_format` is used to format the *date* part of a *date_time* and is either a standard
    format or a format skeleton.

    * If `:date_format` is not specified then the *date* format is defined by the `:format`
      option.

    * If `:date_format` is a format skeleton it may only include format fields
      appropriate for a *date*.

    * :date_format` may only be specified if `:format` is a standard format.

  * `:time_format` is used to format the *time* part of a *date_time* and is either a standard
    format or a format skeleton.

    * If `:time_format` is not specified then the *time* format is defined by the `:format`
      option.

    * If `:time_format` is a format skeleton it may only include format fields
      appropriate for a *time*.

    * :time_format` may only be specified if `:format` is a standard format.

  * `:style` is either `:at` or `:default`. When set to `:at` the *date_time* may
    be formatted with a localised string representing `<date> at <time>` if such
    a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

  * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
    formats have two variants - one using Unicode spaces (typically non-breaking space) and
    another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
    use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
    to see which formats have these variants. See [Variant Preference](#variant-preference)
    below for more information.

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:number_system` a number system into which the formatted *date_time* digits should
    be transliterated. See `Cldr.known_number_systems/0`. The default is
    the number system associated with the `:locale`.

  * `:separators` selects which of the available symbol
    sets should be used when formatting fractional seconds (format
    character `S`).  The default is `:standard`. Some limited locales have an alternative `:us`
    variant that can be used. See `Cldr.Number.Symbol.number_symbols_for/3`
    for the symbols supported for a given locale and number system.

  * `:era` which, if set to `:variant`, will use a variant for the era if one
    is available in the requested locale. In the `:en` locale, for example, `era: :variant`
    will return `CE` instead of `AD` and `BCE` instead of `BC`.

  * `:period` which, if set to `:variant`, will use a variant for the time period and flexible
    time period if one is available in the locale.  For example, in the `:en` locale
    `period: :variant` will return "pm" instead of "PM".

  ### Variant Preference

  * A small number of formats have one of two different alternatives, each with their own
    preference specifier. The preferences are specified with the `:prefer` option to
    `Cldr.Date.to_string/3`. The preference is expressed as an atom, or a list of one or two
    atoms with one atom being either `:unicode` or `:ascii` and one atom being either
    `:default` or `:variant`.

    * Some formats (at the time of publishng only *time* formats but that
      may change in the future) have `:unicode` and `:ascii` versions of the format. The
      difference is the use of ascii space (0x20) as a separateor in the `:ascii` verison
      whereas the `:unicode` version may use non-breaking or other space characters. The
      default is `:unicode` and this is the strongly preferred option. The `:ascii` format
      is primarily to support legacy use cases and is not recommended. See
      `Cldr.Time.available_formats/3` to see which formats have these variants.

    * Some formats (at the time of publishing, only *date* and *date_time* formats) have
      `:default` and `:variant` versions of the format. These variant formats are only
      included in a small number of locales. For example, the `:"en-CA"` locale, which has
      a `:default` format respecting typical Canadian formatting and a `:variant` that is
      more closely aligned to US formatting. The default is `:default`.

  ### Notes

  * If the provided `date_time` contains only *date* fields, the call is delegated to
    `Cldr.Date.to_string/2`.

  * If the provided `date_time` contains only *time* fields, the call is delegated to
    `Cldr.Time.to_string/2`.

  ### Returns

  * `formatted_date_time` or

  * raises an exception.

  ### Examples

      iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, locale: :en)
      "Jan 1, 2000, 11:59:59 PM"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :long, locale: :en)
      "January 1, 2000, 11:59:59 PM UTC"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :en)
      "Saturday, January 1, 2000, 11:59:59 PM Coordinated Universal Time"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :fr)
      "samedi 1 janvier 2000, 23:59:59 temps universel coordonné"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      "semaine 1 (janvier)"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      "semaine 1 de 2000"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, date_format: :yMd, time_format: :hms)
      "1/1/2000, 11:59:59 PM"

  """
  @spec to_string!(Cldr.Calendar.any_date_time(), Cldr.backend(), options()) ::
          String.t() | no_return()

  @spec to_string!(Cldr.Calendar.any_date_time(), options(), []) ::
          String.t() | no_return()

  def to_string!(date_time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(date_time, backend, options) do
    case to_string(date_time, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @doc """
  Returns a map of the standard date_time formats for a given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_formats(:en)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1}, {0}",
         full: "{1}, {0}"
       }}

      iex> Cldr.DateTime.Format.date_time_formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1}, {0}",
         full: "{1}, {0}"
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
  Returns a map of the available date_time formats for a
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
         MMMMW: %{
           other: "'week' W 'of' MMMM",
           one: "'week' W 'of' MMMM",
           pluralize: :week_of_month
         },
         Ehm: %{unicode: "E h:mm a", ascii: "E h:mm a"},
         y: "y",
         MMMd: "MMM d",
         yyMd: "M/d/yy",
         GyM: "M/y G",
         hv: %{unicode: "h a v", ascii: "h a v"},
         Hm: "HH:mm",
         Bhms: "h:mm:ss B",
         ms: "mm:ss",
         yMd: "M/d/y",
         GyMMM: "MMM y G",
         GyMMMEd: "E, MMM d, y G",
         yMMMd: "MMM d, y",
         EBh: "E h B",
         Gy: "y G",
         Hmsv: "HH:mm:ss v",
         hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"},
         M: "L",
         h: %{unicode: "h a", ascii: "h a"},
         Hms: "HH:mm:ss",
         yMMMMd: "MMMM d, y",
         EHm: "E HH:mm",
         ahmmsszzzz: %{unicode: "h:mm:ss a zzzz", ascii: "h:mm:ss a zzzz"},
         MMM: "LLL",
         ahmmssz: %{unicode: "h:mm:ss a z", ascii: "h:mm:ss a z"},
         d: "d",
         Hmv: "HH:mm v",
         GyMd: "M/d/y G",
         yQQQ: "QQQ y",
         yMMMEd: "E, MMM d, y",
         ahmmss: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         MMMMd: "MMMM d",
         H: "HH",
         MEd: "E, M/d",
         Md: "M/d",
         GyMEd: "E, M/d/y G",
         yMMM: "MMM y",
         EBhms: "E h:mm:ss B",
         yw: %{
           other: "'week' w 'of' Y",
           one: "'week' w 'of' Y",
           pluralize: :week_of_year
         },
         hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
         MMMEd: "E, MMM d",
         hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         EBhm: "E h:mm B",
         EHms: "E HH:mm:ss",
         Hv: "HH'h' v",
         ahmm: %{unicode: "h:mm a", ascii: "h:mm a"},
         hm: %{unicode: "h:mm a", ascii: "h:mm a"},
         GyMMMd: "MMM d, y G",
         yMEd: "E, M/d/y",
         Eh: %{unicode: "E h a", ascii: "E h a"},
         Bh: "h B",
         Ehms: %{unicode: "E h:mm:ss a", ascii: "E h:mm:ss a"},
         yMMMM: "MMMM y",
         yQQQQ: "QQQQ y",
         yMMMMEEEEd: "EEEE, MMMM d, y",
         E: "ccc",
         yM: "M/y",
         Bhm: "h:mm B",
         Ed: "d E"
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

  defp normalize_options(date_time, backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)

    calendar = Map.get(date_time, :calendar, Cldr.Calendar.Gregorian)
    date_time = Map.put_new(date_time, :calendar, calendar)

    {format, date_format, time_format} =
      formats_from_options(date_time, nil, nil, nil, @default_standard_format)

    options =
      %{
        locale: locale,
        number_system: number_system,
        format: format,
        date_format: date_format,
        time_format: time_format,
        style: @default_style,
        prefer: [@default_prefer],
        separators: @default_separators
      }

    {:ok, date_time, options}
  end

  defp normalize_options(date_time, _backend, options) when is_map(options) do
    {:ok, date_time, options}
  end

  defp normalize_options(date_time, backend, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)

    calendar = Map.get(date_time, :calendar, Cldr.Calendar.Gregorian)
    date_time = Map.put_new(date_time, :calendar, calendar)

    style = options[:style] || @default_style
    prefer = Keyword.get(options, :prefer, @default_prefer) |> List.wrap()

    format = options[:format]
    date_format = options[:date_format]
    time_format = options[:time_format]

    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)
    separators = Keyword.get(options, :separators, @default_separators)

    {format, date_format, time_format} =
      formats_from_options(date_time, format, date_format, time_format, @default_standard_format)

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
        |> Map.put(:separators, separators)

      {:ok, date_time, options}
    end
  end

  @doc false
  def format_for_skeleton(format, standard_format, skeleton, locale, calendar, backend) do
    {:ok, available_formats} = available_formats(locale, calendar, backend)

    case Map.fetch(available_formats, skeleton) do
      {:ok, format_pattern} ->
        {:ok, format_pattern}

      :error ->
        {:error,
         {
           Cldr.DateTime.UnresolvedFormat,
           "Standard format #{inspect(format)} could not be resolved from " <>
             "#{inspect(standard_format)}"
         }}
    end
  end

  # Only a single format, which is applied to date and time and to
  # the composition format.
  defp validate_formats_consistent(format, nil = _date_format, nil = _time_format)
       when is_atom(format) or is_binary(format) do
    :ok
  end

  # No general format, just date and time format. We will derive the
  # joining format later.
  defp validate_formats_consistent(nil, date_format, time_format)
       when not is_nil(date_format) and not is_nil(time_format) do
    :ok
  end

  # All the formats are short, medium, long or full
  defp validate_formats_consistent(format, date_format, time_format)
       when format in @standard_formats and date_format in @standard_formats and
              time_format in @standard_formats do
    :ok
  end

  # Joining format is short, medium, long or full and date_foramt and
  # time_format are an atom (including nil) or a string.
  defp validate_formats_consistent(format, date_format, time_format)
       when (format in @standard_formats or is_nil(format)) and
              (is_atom(date_format) or is_binary(date_format)) and
              (is_binary(format) or is_atom(time_format)) do
    :ok
  end

  defp validate_formats_consistent(format, date_format, time_format)
       when is_atom(format) or is_binary(format) do
    {:error,
     {Cldr.DateTime.InvalidFormat,
      ":date_format and :time_format cannot be specified if :format is also specified as " <>
        "a format id or a format string. Found [format: #{inspect(format)}, time_format: #{inspect(time_format)}, " <>
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
  defp formats_from_options(date_time, nil, nil, nil, _default)
       when is_any_date_time(date_time) do
    {@default_standard_format, @default_standard_format, @default_standard_format}
  end

  defp formats_from_options(_date_time, format, nil, nil, _default)
       when format in @standard_formats do
    {format, format, format}
  end

  # When we have a string or atom format then it controls everything and there
  # should be no separate date format or time format
  defp formats_from_options(_date_time, format, nil, nil, _default)
       when is_binary(format) do
    {format, nil, nil}
  end

  defp formats_from_options(_date_time, format, nil, nil, _default)
       when is_atom(format) do
    {format, nil, nil}
  end

  # Replace nil date and time formats with the format iff format is
  # one of the standard types.
  defp formats_from_options(_date_time, format, date_format, nil, _default)
       when format in @standard_formats do
    {format, date_format, format}
  end

  defp formats_from_options(_date_time, format, nil, time_format, _default)
       when format in @standard_formats do
    {format, format, time_format}
  end

  defp formats_from_options(_date_time, format, nil, time_format, _default)
       when time_format in @standard_formats do
    {format, time_format, time_format}
  end

  defp formats_from_options(_date_time, format, date_format, nil, _default)
       when date_format in @standard_formats do
    {format, date_format, date_format}
  end

  # If standard date and time formats but no format, we'll derive the
  # format later on.
  defp formats_from_options(_date_time, nil = format, date_format, time_format, _default)
       when date_format in @standard_formats and time_format in @standard_formats do
    {format, date_format, time_format}
  end

  defp formats_from_options(_date_time, format, date_format, time_format, _default) do
    {format, date_format, time_format}
  end

  # Resolve the actual format string for the date time format.
  # Unless we need to derive the format, this only touches `format`,
  # not `date_format` or `time_format`.

  # If its a partial date_time and a standard format is requested, its an error
  defp find_format(date_time, format, _locale, _calendar, _backend, _options)
       when format in @standard_formats and not is_any_date_time(date_time) do
    {:error,
     {
       Cldr.DateTime.UnresolvedFormat,
       "Standard formats are not available for partial date times"
     }}
  end

  # Standard format, at style
  defp find_format(_date_time, format, locale, calendar, backend, %{style: :at} = options)
       when format in @standard_formats do
    with {:ok, formats} <- Format.date_time_at_formats(locale, calendar, backend),
         {:ok, format} <- preferred_format(formats, format, options.prefer) do
      {:ok, format, options}
    end
  end

  # Standard format, standard style
  defp find_format(_date_time, format, locale, calendar, backend, options)
       when format in @standard_formats do
    with {:ok, formats} <- Format.date_time_formats(locale, calendar, backend),
         {:ok, format} <- preferred_format(formats, format, options.prefer) do
      {:ok, format, options}
    end
  end

  # The format is specified as a skeleton so we need to find
  # the best match for it. The best match can be a single skeleton
  # (that is guaranteed to be in the date_time_available_formats list)
  # or two skeletons - one for the date part and one for the time part.
  defp find_format(date_time, format, locale, calendar, backend, options)
       when is_skeleton(format) do
    case Match.best_match(format, locale, calendar, backend) do
      {:ok, {date_format, time_format}} ->
        options =
          options
          |> Map.put(:date_format, date_format)
          |> Map.put(:time_format, time_format)
          |> Map.put(:requested_skeleton, format)

        # Since the return is a date and a time format, we need
        # to derive the joining format.
        find_format(date_time, nil, locale, calendar, backend, options)

      {:ok, format} ->
        with {:ok, skeleton_tokens} <- Compiler.tokenize_skeleton(options.format),
             {:ok, formats} <- Format.date_time_available_formats(locale, calendar, backend),
             {:ok, preferred_format} <- preferred_format(formats, format, options.prefer),
             {:ok, format_pattern} <- Match.adjust_field_lengths(preferred_format, skeleton_tokens) do
          {:ok, format_pattern, options}
        end

      error ->
        error
    end
  end

  # We need to derive the format, and maybe even date_format and time_format too.
  defp find_format(date_time, nil, locale, calendar, backend, options) do
    date_format = options.date_format
    time_format = options.time_format

    with {:ok, date_format} <-
           date_format(date_time, date_format, locale, calendar, backend, options),
         {:ok, time_format} <-
           time_format(date_time, time_format, locale, calendar, backend, options),
         {:ok, format} <-
           resolve_format(date_format, options.style, locale, calendar, backend) do
      options =
        options
        |> Map.put(:date_format, date_format)
        |> Map.put(:time_format, time_format)

      {:ok, format, options}
    end
  end

  # Straight up format pattern
  defp find_format(_date_time, format_pattern, _locale, _calendar, _backend, options)
       when is_binary(format_pattern) do
    {:ok, format_pattern, options}
  end

  # Format with a number system
  defp find_format(date_time, %{} = format, locale, calendar, backend, options) do
    %{number_system: number_system, format: format} = format

    {:ok, format_string, options} =
      find_format(date_time, format, locale, calendar, backend, options)

    {:ok, %{number_system: number_system, format: format_string}, options}
  end

  @doc false
  def best_match(format, locale, calendar, backend, options) do
    skeleton = options[:requested_skeleton] || format

    with {:ok, formats} <- Format.date_time_available_formats(locale, calendar, backend),
         {:ok, skeleton_tokens} <- Compiler.tokenize_skeleton(skeleton),
         {:ok, matched} <- Match.best_match(format, locale, calendar, backend),
         {:ok, format_pattern} <- Map.fetch(formats, matched) do
      Match.adjust_field_lengths(format_pattern, skeleton_tokens)
    else
      :error ->
        {:error, Match.no_format_resolved_error(format)}

      other ->
        other
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

  defp resolve_format(%{format: format}, style, locale, calendar, backend) do
    resolve_format(format, style, locale, calendar, backend)
  end

  defp resolve_format(date_format, style, locale, calendar, backend) do
    {:ok, formats} = formats_for_style(style, locale, calendar, backend)

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

  defp formats_for_style(:at, locale, calendar, backend) do
    Cldr.DateTime.Format.date_time_at_formats(locale, calendar, backend)
  end

  defp formats_for_style(_standard, locale, calendar, backend) do
    Cldr.DateTime.Format.date_time_formats(locale, calendar, backend)
  end

  # We need to derive the date format now since that data
  # is used to establish what date_time format we derive.

  defp date_format(date_time, nil, locale, calendar, backend, options) do
    format_id = Cldr.Date.derive_format_id(date_time)
    date_format(date_time, format_id, locale, calendar, backend, options)
  end

  defp date_format(date_time, format_id, locale, calendar, backend, options) do
    Cldr.Date.find_format(date_time, format_id, locale, calendar, backend, options)
  end

  defp time_format(date_time, nil, locale, calendar, backend, options) do
    format_id = Cldr.Time.derive_format_id(date_time)
    time_format(date_time, format_id, locale, calendar, backend, options)
  end

  defp time_format(date_time, format_id, locale, calendar, backend, options) do
    Cldr.Time.find_format(date_time, format_id, locale, calendar, backend, options)
  end

  # FIXME These functions don't consider the impact
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
  def derive_format_id(date_time, field_map, field_names) do
    date_time
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
          "Invalid date_time format #{inspect(format)}. " <>
            "The valid formats are #{inspect(@standard_formats)}."}}
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

  def apply_preference(%{default: default}, _preference) do
    {:ok, default}
  end

  def apply_preference(%{unicode: unicode}, _preference) do
    {:ok, unicode}
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
