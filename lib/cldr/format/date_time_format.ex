defmodule Cldr.DateTime.Format do
  @moduledoc """
  Manages the Date, Time and DateTime formats
  defined by CLDR.

  The functions in `Cldr.DateTime.Format` are
  primarily concerned with encapsulating the
  data from CLDR in functions that are used
  during the formatting process.

  """

  alias Cldr.Locale
  alias Cldr.LanguageTag

  @typedoc """
  A format skeleton is a string consisting of [format
  symbols](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)
  which is used to find the best match from the list of
  formats returned by `Cldr.DateTime.Format.date_time_available_formats/3`
  """
  @type format_skeleton :: atom() | binary()

  @typedoc """
  The standard formats of `:full`,
  `:long`, `:medium` and `:short` are used
  to resolve standard formats in a locale independent
  way. The resolve to a skeleton ID as an atom.
  """
  @type standard_formats :: %{
          full: format_skeleton(),
          long: format_skeleton(),
          medium: format_skeleton(),
          short: format_skeleton()
        }

  @typedoc """
  A format_id is an atom that indexes into the map returned by
  `Cldr.DateTime.Format.date_time_available_formats/3` to
  resolve a format string.
  """
  @type format_id :: atom()

  @standard_formats [:short, :medium, :long, :full]

  @date_fields [
    "G",
    "y",
    "Y",
    "u",
    "U",
    "r",
    "Q",
    "q",
    "M",
    "L",
    "W",
    "w",
    "d",
    "D",
    "F",
    "g",
    "E",
    "e",
    "c"
  ]

  @time_fields [
    "h",
    "H",
    "k",
    "K",
    "m",
    "s",
    "S",
    "v",
    "V",
    "z",
    "Z",
    "x",
    "X",
    "O",
    "a",
    "b",
    "B"
  ]

  @doc false
  def standard_formats do
    @standard_formats
  end

  @doc false
  def date_fields do
    @date_fields
  end

  @doc false
  def time_fields do
    @time_fields
  end

  @doc false
  def format_list(config) do
    locale_names = Cldr.Locale.Loader.known_locale_names(config)
    backend = config.backend

    ((known_formats(&all_date_formats(&1, backend), locale_names) ++
        known_formats(&all_time_formats(&1, backend), locale_names) ++
        known_formats(&all_date_time_formats(&1, backend), locale_names) ++
        known_formats(&all_interval_formats(&1, backend), locale_names)) ++
       config.precompile_date_time_formats ++ precompile_interval_formats(config))
    |> only_compilable_formats()
    |> Enum.uniq()
    |> Enum.reject(&is_atom/1)
  end

  defp only_compilable_formats(formats) do
    Enum.reduce(formats, [], fn
      f, acc when is_binary(f) -> [f | acc]
      %{number_system: _} = format, acc -> [format | acc]
      map, acc when is_map(map) -> Map.values(map) ++ acc
      list, acc when is_list(list) -> acc
      _other, acc -> acc
    end)
  end

  defp precompile_interval_formats(config) do
    config.precompile_interval_formats
    |> Enum.flat_map(&split_interval!/1)
    |> List.flatten()
  end

  @doc """
  Returns a list of calendars defined for a given locale.

  ### Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.calendars_for(:en, MyApp.Cldr)
      {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
       :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :iso8601, :japanese, :persian, :roc]}

  """
  @spec calendars_for(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, [Cldr.Calendar.calendar(), ...]} | {:error, {atom, String.T}}

  def calendars_for(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.calendars_for(locale)
  end

  @doc """
  Returns the GMT offset format list for a
  for a timezone offset for a given locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.gmt_format(:en, MyApp.Cldr)
      {:ok, ["GMT", 0]}

  """
  @spec(
    gmt_format(Locale.locale_reference(), Cldr.backend()) ::
      {:ok, [non_neg_integer | String.t(), ...]},
    {:error, {atom, String.t()}}
  )

  def gmt_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_format(locale)
  end

  @doc """
  Returns the GMT format string for a
  for a timezone with an offset of zero for
  a given locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.gmt_zero_format(:en, MyApp.Cldr)
      {:ok, "GMT"}

  """
  @spec gmt_zero_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def gmt_zero_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_zero_format(locale)
  end

  @doc """
  Returns the GMT format string for a for an unkown GMT offset.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.gmt_unknown_format(:en, MyApp.Cldr)
      {:ok, "GMT+?"}

  """
  @spec gmt_unknown_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def gmt_unknown_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_unknown_format(locale)
  end

  @doc """
  Returns the timezone display data for
  a locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  """
  @doc since: "2.33.0"

  @spec timezones(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def timezones(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.timezones(locale)
  end

  @doc """
  Returns the metazone data for
  a locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  """
  @doc since: "2.33.0"

  @spec metazones(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def metazones(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.metazones(locale)
  end

  @doc """
  Returns the regional format for
  formatting time zones.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.zone_region_format(:en, MyApp.Cldr)
      {:ok,
       %{
         standard: [0, " Standard Time"],
         generic: [0, " Time"],
         daylight: [0, " Daylight Time"]
       }}

  """
  @doc since: "2.33.0"

  @spec zone_region_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, %{:daylight => list(), :generic => list(), :standard => list()}}
          | {:error, {atom, String.t()}}

  def zone_region_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.zone_region_format(locale)
  end

  @doc """
  Returns the time zone fallback format for
  formatting time zones.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.zone_fallback_format(:en, MyApp.Cldr)
      {:ok, [1, " (", 0, ")"]}

  """
  @doc since: "2.33.0"

  @spec zone_fallback_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, list()} | {:error, {atom, String.t()}}

  def zone_fallback_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.zone_fallback_format(locale)
  end

  @doc """
  Returns the positive and negative hour format
  for a timezone offset for a given locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Example

      iex> Cldr.DateTime.Format.hour_format(:en, MyApp.Cldr)
      {:ok, {"+HH:mm", "-HH:mm"}}

  """
  @spec hour_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, {String.t(), String.t()}} | {:error, {atom, String.t()}}

  def hour_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.hour_format(locale)
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

      iex> Cldr.DateTime.Format.date_formats(:en, :gregorian, MyApp.Cldr)
      {:ok,
       %Cldr.Date.Formats{
         short: :yyMd,
         medium: :yMMMd,
         long: :yMMMMd,
         full: :yMMMMEEEEd
       }}

      iex> Cldr.DateTime.Format.date_formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
       %Cldr.Date.Formats{
         short: :GGGGGyMd,
         medium: :GyMMMd,
         long: :GyMMMMd,
         full: :GyMMMMEEEEd
       }}

  """
  @spec date_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, Cldr.DateTime.Format.standard_formats()} | {:error, {atom, String.t()}}

  def date_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_formats(locale, calendar)
  end

  @doc """
  Returns a map of the standard time formats for a given locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.time_formats(:en)
      {:ok,
       %Cldr.Time.Formats{
         short: :ahmm,
         medium: :ahmmss,
         long: :ahmmssz,
         full: :ahmmsszzzz
       }}

      iex> Cldr.DateTime.Format.time_formats(:en, :buddhist)
      {:ok,
       %Cldr.Time.Formats{
         short: :ahmm,
         medium: :ahmmss,
         long: :ahmmssz,
         full: :ahmmsszzzz
       }}

  """
  @spec time_formats(
          Locale.locale_name() | String.t() | LanguageTag,
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, standard_formats} | {:error, {atom, String.t()}}

  def time_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.time_formats(locale, calendar)
  end

  @doc """
  Returns a map of the standard datetime formats for a given locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.date_time_formats(:en)
      {:ok,
        %Cldr.DateTime.Formats{
          full: "{1}, {0}",
          long: "{1}, {0}",
          medium: "{1}, {0}",
          short: "{1}, {0}"
      }}

      iex> Cldr.DateTime.Format.date_time_formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
        %Cldr.DateTime.Formats{
          full: "{1}, {0}",
          long: "{1}, {0}",
          medium: "{1}, {0}",
          short: "{1}, {0}"
      }}

  """
  @spec date_time_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_formats(locale, calendar)
  end

  @doc """
  Returns a map of the standard datetime "at" formats for a given
  locale and calendar.

  An "at" format is one where the datetime is formatted with the
  date part separated from the time part by a localized version
  of "at".

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.date_time_at_formats(:en)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1} 'at' {0}",
         full: "{1} 'at' {0}"
       }}

      iex> Cldr.DateTime.Format.date_time_at_formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1} 'at' {0}",
         full: "{1} 'at' {0}"
       }}

  """
  @spec date_time_at_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_at_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_at_formats(locale, calendar)
  end

  @doc """
  Returns a map of the standard datetime relative formats for a given
  locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.date_time_relative_formats(:en)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1} 'at' {0}",
         full: "{1} 'at' {0}"
       }}

      iex> Cldr.DateTime.Format.date_time_relative_formats(:en, :buddhist, MyApp.Cldr)
      {:ok,
       %Cldr.DateTime.Formats{
         short: "{1}, {0}",
         medium: "{1}, {0}",
         long: "{1} 'at' {0}",
         full: "{1} 'at' {0}"
       }}

  """
  @spec date_time_relative_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_relative_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_relative_formats(locale, calendar)
  end

  @doc """
  Returns a datetime format for a given locale and format style.

  ### Arguments

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `:format` is the format style requested. The valid values are
    `:short`, `:medium`, `:long` or `:full`. The default is `:medium`.

  ### Returns

  * `{:ok, format_string}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Format.date_time_format()
      {:ok, "{1}, {0}"}

      iex> Cldr.DateTime.Format.date_time_format(format: :full)
      {:ok, "{1}, {0}"}

      iex> Cldr.DateTime.Format.date_time_format(locale: :de, format: :full)
      {:ok, "{1}, {0}"}

      iex> Cldr.DateTime.Format.date_time_format(locale: :de, format: :unknown)
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "Unknown value for option format: :unknown"}}

  """
  @doc since: "2.23.0"
  @spec date_time_format(options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def date_time_format(options \\ []) do
    with {locale, backend} <- Cldr.locale_and_backend_from(options),
         {:ok, calendar} <- Cldr.Calendar.calendar_from_locale(locale),
         {:ok, formats} <- date_time_formats(locale, calendar.cldr_calendar_type(), backend) do
      prefer = Keyword.get(options, :prefer, :unicode)
      style = Keyword.get(options, :format, :medium)
      resolve_format_style_and_preference(formats, style, prefer)
    end
  end

  @doc """
  Returns a date format for a given locale and format style.

  ### Arguments

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `:format` is the format style requested. The valid values are
    `:short`, `:medium`, `:long` or `:full`. The default is `:medium`.

  ### Returns

  * `{:ok, format_string}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Format.date_format()
      {:ok, :yMMMd}

      iex> Cldr.DateTime.Format.date_format(format: :full)
      {:ok, :yMMMMEEEEd}

      iex> Cldr.DateTime.Format.date_format(locale: :de, format: :full)
      {:ok, :yMMMMEEEEd}

      iex> Cldr.DateTime.Format.date_format(locale: :de, format: :unknown)
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "Unknown value for option format: :unknown"}}

  """
  @doc since: "2.23.0"
  @spec date_format(options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def date_format(options \\ []) do
    with {locale, backend} <- Cldr.locale_and_backend_from(options),
         {:ok, calendar} <- Cldr.Calendar.calendar_from_locale(locale),
         {:ok, formats} <- date_formats(locale, calendar.cldr_calendar_type(), backend) do
      prefer = Keyword.get(options, :prefer, :unicode)
      style = Keyword.get(options, :format, :medium)
      resolve_format_style_and_preference(formats, style, prefer)
    end
  end

  @doc """
  Returns a date format for a given locale and format style.

  ### Arguments

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `:format` is the format style requested. The valid values are
    `:short`, `:medium`, `:long` or `:full`. The default is `:medium`.

  * `:prefer` is either `:unicode` (the default) or `:ascii`. When a locale
    offers both a unicode and ascii variant of the requested format style,
    the preferred variant is returned if one is available for the given locale.
    If the preferred variant is not available then the ascii version is returned.

  ### Returns

  * `{:ok, format_string}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Format.time_format()
      {:ok, :ahmmss}

      iex> Cldr.DateTime.Format.time_format(format: :full)
      {:ok, :ahmmsszzzz}

      iex> Cldr.DateTime.Format.time_format(format: :full, locale: :ja)
      {:ok, :Hmmsszzzz}

      iex> Cldr.DateTime.Format.time_format(format: :full, prefer: :unicode)
      {:ok, :ahmmsszzzz}

      iex> Cldr.DateTime.Format.time_format(format: :unknown)
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "Unknown value for option format: :unknown"}}

  """
  @doc since: "2.23.0"
  @spec time_format(options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def time_format(options \\ []) do
    with {locale, backend} <- Cldr.locale_and_backend_from(options),
         {:ok, calendar} <- Cldr.Calendar.calendar_from_locale(locale),
         {:ok, formats} <- time_formats(locale, calendar.cldr_calendar_type(), backend) do
      prefer = Keyword.get(options, :prefer, :unicode)
      style = Keyword.get(options, :format, :medium)
      resolve_format_style_and_preference(formats, style, prefer)
    end
  end

  defp resolve_format_style_and_preference(formats, style, prefer)
       when is_map_key(formats, style) do
    style = Map.fetch!(formats, style)

    cond do
      is_map(style) ->
        {:ok, Map.get(style, prefer) || Map.get(style, :ascii)}

      is_binary(style) ->
        {:ok, style}

      is_list(style) ->
        {:ok, style}

      is_atom(style) ->
        {:ok, style}
    end
  end

  defp resolve_format_style_and_preference(_formats, style, _prefer) do
    {:error, {Cldr.DateTime.UnresolvedFormat, "Unknown value for option format: #{inspect(style)}"}}
  end

  @doc """
  Returns a map of the available datetime formats for a
  given locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.date_time_available_formats(:en)
      {:ok,
       %{
         yQQQ: "QQQ y",
         yyMd: "M/d/yy",
         hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"},
         Bh: "h B",
         y: "y",
         M: "L",
         MMMMW: %{
           other: "'week' W 'of' MMMM",
           one: "'week' W 'of' MMMM",
           pluralize: :week_of_month
         },
         Hv: "HH'h' v",
         hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         hv: %{unicode: "h a v", ascii: "h a v"},
         hm: %{unicode: "h:mm a", ascii: "h:mm a"},
         Hmv: "HH:mm v",
         hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
         EBhm: "E h:mm B",
         ahmmss: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         GyMMMEd: "E, MMM d, y G",
         Bhms: "h:mm:ss B",
         GyMEd: "E, M/d/y G",
         MMMMd: "MMMM d",
         Hm: "HH:mm",
         Ed: "d E",
         GyM: "M/y G",
         GyMMMd: "MMM d, y G",
         Bhm: "h:mm B",
         yMMMEd: "E, MMM d, y",
         h: %{unicode: "h a", ascii: "h a"},
         yMMMM: "MMMM y",
         yMEd: "E, M/d/y",
         Ehm: %{unicode: "E h:mm a", ascii: "E h:mm a"},
         MEd: "E, M/d",
         d: "d",
         EHms: "E HH:mm:ss",
         yQQQQ: "QQQQ y",
         yMMMMd: "MMMM d, y",
         yMMM: "MMM y",
         yMMMd: "MMM d, y",
         GyMMM: "MMM y G",
         Hmsv: "HH:mm:ss v",
         ahmm: %{unicode: "h:mm a", ascii: "h:mm a"},
         Md: "M/d",
         yMMMMEEEEd: "EEEE, MMMM d, y",
         yMd: "M/d/y",
         ahmmsszzzz: %{unicode: "h:mm:ss a zzzz", ascii: "h:mm:ss a zzzz"},
         EBhms: "E h:mm:ss B",
         ahmmssz: %{unicode: "h:mm:ss a z", ascii: "h:mm:ss a z"},
         ms: "mm:ss",
         yw: %{
           other: "'week' w 'of' Y",
           one: "'week' w 'of' Y",
           pluralize: :week_of_year
         },
         MMMd: "MMM d",
         Gy: "y G",
         GyMd: "M/d/y G",
         EHm: "E HH:mm",
         yM: "M/y",
         MMM: "LLL",
         H: "HH",
         Hms: "HH:mm:ss",
         EBh: "E h B",
         E: "ccc",
         Eh: %{unicode: "E h a", ascii: "E h a"},
         MMMEd: "E, MMM d",
         Ehms: %{unicode: "E h:mm:ss a", ascii: "E h:mm:ss a"}
       }}

  """
  @spec date_time_available_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_available_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_available_formats(locale, calendar)
  end

  @doc false
  @spec date_time_available_format_tokens(
          locale :: Locale.locale_reference(),
          calendar :: Cldr.Calendar.calendar(),
          backend :: Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}
  def date_time_available_format_tokens(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_available_format_tokens(locale, calendar)
  end

  @doc """
  Returns a map of the interval formats for a
  given locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      Cldr.DateTime.Format.interval_formats(:en, :gregorian, MyApp.Cldr)
      => {:ok,
       %{
         bh: %{b: ["h B", "h B"], h: ["h", "h B"]},
         bhm: %{b: ["h:mm B", "h:mm B"], h: ["h:mm", "h:mm B"], m: ["h:mm", "h:mm B"]},
         d: %{d: ["d", "d"]},
         gy: %{g: ["y G", "y G"], y: ["y", "y G"]},
         ...

  """
  @spec interval_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}

  def interval_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_interval_formats(locale, calendar)
  end

  @doc """
  Returns a list of the date_time format types that are
  available in all known locales.

  The format types returned by `common_date_time_format_names`
  are guaranteed to be available in all known locales,

  ### Example:

      iex> Cldr.DateTime.Format.common_date_time_format_names()
      [:Bh, :Bhm, :Bhms, :E, :EBh, :EBhm, :EBhms, :EHm, :EHms, :Ed, :Eh, :Ehm, :Ehms,
       :Gy, :GyM, :GyMEd, :GyMMM, :GyMMMEd, :GyMMMd, :GyMd, :H, :Hm, :Hms, :Hmsv,
       :Hmv, :Hv, :M, :MEd, :MMM, :MMMEd, :MMMMW, :MMMMd, :MMMd, :Md, :d, :h, :hm,
       :hms, :hmsv, :hmv, :hv, :ms, :y, :yM, :yMEd, :yMMM, :yMMMEd, :yMMMM, :yMMMd,
       :yMd, :yQQQ, :yQQQQ, :yw]

  """
  @spec common_date_time_format_names(backend :: Cldr.backend()) :: [format_id()]
  def common_date_time_format_names(backend \\ Cldr.Date.default_backend()) do
    datetime_module = Module.concat(backend, DateTime.Format)

    Cldr.known_locale_names(backend)
    |> Enum.map(&datetime_module.date_time_available_formats/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Map.keys/1)
    |> Enum.map(&MapSet.new/1)
    |> intersect_mapsets()
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp known_formats(list, locale_names) do
    locale_names
    |> Enum.reduce([], fn l, acc -> acc ++ list.(l) end)
    |> Enum.uniq()
  end

  @doc false
  def all_date_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.date_formats/2)
  end

  @doc false
  def all_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.time_formats/2)
  end

  @doc false
  def all_date_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)

    all_formats_for(locale, backend, &datetime_backend.date_time_formats/2) ++
      all_formats_for(locale, backend, &datetime_backend.date_time_at_formats/2) ++
      all_formats_for(locale, backend, &datetime_backend.date_time_available_formats/2)
  end

  @doc false
  def all_interval_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_interval_formats_for(locale, backend, &datetime_backend.date_time_interval_formats/2)
  end

  @doc false
  def all_formats_for(locale, backend, type_function) do
    with {:ok, calendars} <- calendars_for(locale, backend) do
      Enum.reduce(calendars, [], fn calendar, acc ->
        {:ok, calendar_formats} = type_function.(locale, calendar)

        map =
          if is_struct(calendar_formats),
            do: Map.from_struct(calendar_formats),
            else: calendar_formats

        formats =
          map
          |> Map.values()
          |> Enum.map(fn
            format when is_binary(format) -> format
            %{format: format, number_system: _} -> format
            %{unicode: unicode, ascii: ascii} -> [unicode, ascii]
            %{default: default} -> default
            other -> other
          end)
          |> List.flatten()

        acc ++ formats
      end)
      |> Enum.uniq()
    end
  end

  @doc false
  def all_interval_formats_for(locale, backend, type_function) do
    with {:ok, calendars} <- calendars_for(locale, backend) do
      Enum.map(calendars, fn calendar ->
        {:ok, calendar_formats} = type_function.(locale, calendar)

        calendar_formats
        |> Map.values()
        |> Enum.filter(&is_map/1)
        |> Enum.flat_map(&Map.values/1)
        |> Enum.map(fn
          %{default: default, variant: variant} -> [default, variant]
          other -> other
        end)
      end)
      |> List.flatten()
      |> Enum.uniq()
    end
  end

  defp intersect_mapsets([a, b | []]) do
    MapSet.intersection(a, b)
  end

  defp intersect_mapsets([a, b | tail]) do
    intersect_mapsets([MapSet.intersection(a, b) | tail])
  end

  @doc false

  # All locales define an hour_format that have the following characteristics:
  #  >  :hour and :minute only (and always both)
  #  >  :minute is always 2 digits: "mm"
  #  >  always have a sign + or -
  #  >  have either a separator of ":", "." or no separator
  # Therefore the format is always either 4 parts (with separator) or 3 parts (without separator)

  # Short format with zero minutes
  def gmt_format_type([sign, hour, _sep, "00"], :short) do
    [sign, String.replace_leading(hour, "0", "")]
  end

  # Short format with minutes > 0
  def gmt_format_type([sign, hour, sep, minute], :short) do
    [sign, String.replace_leading(hour, "0", ""), sep, minute]
  end

  # Long format
  def gmt_format_type([sign, hour, sep, minute], :long) do
    [sign, hour, sep, minute]
  end

  # The case when there is no separator
  def gmt_format_type([sign, hour, minute], format_type) do
    gmt_format_type([sign, hour, "", minute], format_type)
  end

  ### Helpers

  @doc false

  # Used during compilation to split an interval into
  # the from and to parts

  def split_interval(interval) do
    case do_split_interval(interval, [], "") do
      {:error, reason} -> {:error, reason}
      success -> {:ok, success}
    end
  end

  @doc false
  def split_interval!(interval) do
    case do_split_interval(interval, [], "") do
      {:error, {exception, reason}} -> raise exception, reason
      success -> success
    end
  end

  defp do_split_interval("", _acc, left) do
    {:error,
     {Cldr.DateTime.IntervalFormatError, "Invalid datetime interval format #{inspect(left)}"}}
  end

  # Handle default/variant maps

  defp do_split_interval(%{default: default, variant: variant}, _acc, _left) do
    %{default: do_split_interval(default, [], ""), variant: do_split_interval(variant, [], "")}
  end

  # Quoted strings pass through. This assumes the quotes
  # are correctly closed.

  @literal "'"
  defp do_split_interval(<<@literal, rest::binary>>, acc, left) do
    [literal, rest] = String.split(rest, @literal, parts: 2)
    do_split_interval(rest, acc, left <> @literal <> literal <> @literal)
  end

  # characters that are not format characters
  # pass through

  defp do_split_interval(<<c::utf8, rest::binary>>, acc, left)
       when c not in ?a..?z and c not in ?A..?Z do
    do_split_interval(rest, acc, left <> List.to_string([c]))
  end

  # Handle format characters that repeat up to a maximum of
  # 5 times

  defp do_split_interval(
         <<c::binary-1, c::binary-1, c::binary-1, c::binary-1, c::binary-1, rest::binary>>,
         acc,
         left
       ) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 5) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 5))
    end
  end

  defp do_split_interval(
         <<c::binary-1, c::binary-1, c::binary-1, c::binary-1, rest::binary>>,
         acc,
         left
       ) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 4) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 4))
    end
  end

  defp do_split_interval(<<c::binary-1, c::binary-1, c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 3) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 3))
    end
  end

  defp do_split_interval(<<c::binary-1, c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 2) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 2))
    end
  end

  defp do_split_interval(<<c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, c <> rest]
    else
      do_split_interval(rest, [c | acc], left <> c)
    end
  end

  # Per the updated spec we treat format characters as equivalent to their
  # standalone format for the purposes of splitting. ie we treat "L" == "M"
  #
  # Equivalence table:
  # Quarter:  Q, q
  # Month: L, M
  # Week Day: E, e, c

  defp already_seen?("Q", acc), do: "Q" in acc || "q" in acc
  defp already_seen?("q", acc), do: "Q" in acc || "q" in acc
  defp already_seen?("L", acc), do: "L" in acc || "M" in acc
  defp already_seen?("M", acc), do: "L" in acc || "M" in acc
  defp already_seen?("E", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?("e", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?("c", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?(c, acc), do: c in acc
end
