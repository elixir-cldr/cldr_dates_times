defmodule Cldr.DateTime.Timezone do
  @moduledoc """
  Functions to format [IANA time zone IDs](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones),
  including the time zone field of a `t:DateTime.t/0`.

  ### Time Zone Names

  There are three main types of formats for zone identifiers: GMT, generic (wall time), and
  standard/daylight.

  Standard and daylight are equivalent to a particular offset from GMT, and can be represented
  by a GMT offset as a fallback. In general, this is not true for the generic format, which
  is used for picking timezones or for conveying a timezone for specifying a recurring time
  (such as a meeting in a calendar). For either purpose, a GMT offset would lose information.

  > #### Supported Time Zone IDs  {: .info}
  >
  > [NATO time zone names](https://en.wikipedia.org/wiki/Military_time_zone) are not supported, only
  > [IANA time zone IDs](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

  ### Time Zone Format Terminology

  The following terminology defines more precisely the formats that are used.

  #### Generic non-location format

  Reflects "wall time" (what is on a clock on the wall): used
  or recurring events, meetings, or anywhere people do not want to be overly specific.
  For example, "10 am Pacific Time" will be GMT-8 in the winter, and GMT-7 in the summer.

    * "Pacific Time" (long)
    * "PT" (short)

  This format is returned from `Cldr.DateTime.Time.non_location_format/2` with `type: :generic`
  which is the default.

  #### Generic partial location format

  Reflects "wall time": used as a fallback format when
  the generic non-location format is not specific enough. For example:

  * "Pacific Time (Canada)" (long)
  * "PT (Whitehorse)" (short)

  #### Generic location format

  Reflects "wall time": a primary function of this format type is to represent
  a time zone in a list or menu for user selection of time zone. It is also a
  fallback format when there is no translation for the generic non-location format.
  Times could also be organized hierarchically by country for easier lookup.

  * France Time
  * Italy Time
  * Japan Time
  * United States
  * Chicago Time
  * Denver Time
  * Los Angeles Time
  * New York Time
  * United Kingdom Time

  Note: A generic location format is constructed by a part of time zone ID representing
  an exemplar city name or its country as the final fallback. However, there are Unicode
  time zones which are not associated with any locations, such as "Etc/GMT+5" and "PST8PDT".

  Although the date format pattern "VVVV" specifies the generic location format, but it
  displays localized GMT format for these. Some of these time zones observe daylight saving
  time, so the result (localized GMT format) may change depending on input date. For generating
  a list for user selection of time zone with format "VVVV", these non-location zones should
  be excluded.

  This format is returned from `Cldr.DateTime.Time.location_format/2` with `type: :generic` which
  is the default.

  #### Specific non-location format

  Reflects a specific standard or daylight time, which may or may not be the wall time.
  For example, "10 am Pacific Standard Time" will be GMT-8 in the winter and GMT-7 in the summer.

  * "Pacific Standard Time" (long)
  * "PST" (short)
  * "Pacific Daylight Time" (long)
  * "PDT" (short)

  This format is returned from `Cldr.DateTime.Time.non_location_format/2` with `type: :standard` or
  `type :daylight`.

  #### Specific location format

  This format does not have a symbol, but is used in the fallback chain for the specific
  non-location format. Like the generic location format it uses time zone locations, but
  formats these in a zone-variant aware way, e.g. "France Summer Time".

  This format is returned from `Cldr.DateTime.Time.location_format/2` with `type: :standard` or
  `type :daylight`.

  #### Localized GMT format

  A constant, specific offset from GMT (or UTC), which may be in a translated form.
  There are two styles for this.

  The long format always uses 2-digit hours field and minutes field, with optional 2-digit
  seconds field. The short format is intended for the shortest representation and uses hour
  fields without leading zero, with optional 2-digit minutes and seconds fields.

  The digits used for hours, minutes and seconds fields in this format are the locale's
  default decimal digits:

  * "GMT+03:30" (long)
  * "GMT+3:30" (short)
  * "UTC-03.00" (long)
  * "UTC-3" (short)
  * "Гринуич+03:30" (long)

  Otherwise (when the offset from GMT is zero, referring to GMT itself) the style specified
  by the following format is used:

  * "GMT"
  * "UTC"
  * "Гринуич"

  #### ISO 8601 time zone formats

  The formats based on the [ISO 8601] local time difference from UTC ("+" sign is used when
  local time offset is 0), or the UTC indicator ("Z" - only when the local time offset is 0
  and the specifier X* is used). The ISO 8601 basic format does not use a separator character
  between hours and minutes field, while the extended format uses colon (':') as the separator.

  The ISO 8601 basic format with hours and minutes fields is equivalent to RFC 822 zone format.

  * "-0800" (basic)
  * "-08" (basic - short)
  * "-08:00" (extended)
  * "Z" (UTC)

  Note: This specification extends the original ISO 8601 formats and some format specifiers
  append seconds field when necessary.

  ### Examples for fomat differences

  The following shows representative examples of the different formats:

    iex> {:ok, date_time} = DateTime.new(~D[2025-07-01], ~T[00:00:00], "Australia/Sydney")
    iex> Cldr.DateTime.Timezone.non_location_format(date_time, type: :daylight)
    {:ok, "Australian Eastern Daylight Time"}
    iex> Cldr.DateTime.Timezone.non_location_format(date_time, type: :specific)
    {:ok, "Australian Eastern Standard Time"}
    iex> Cldr.DateTime.Timezone.non_location_format(date_time, type: :generic)
    {:ok, "Australian Eastern Time"}
    iex> Cldr.DateTime.Timezone.location_format(date_time, type: :daylight)
    {:ok, "Sydney Daylight Time"}
    iex> Cldr.DateTime.Timezone.location_format(date_time, type: :specific)
    {:ok, "Sydney Standard Time"}
    iex> Cldr.DateTime.Timezone.location_format(date_time, type: :generic)
    {:ok, "Sydney Time"}
    iex> Cldr.DateTime.Timezone.gmt_format(date_time)
    {:ok, "GMT+10:00"}
    iex> Cldr.DateTime.Timezone.iso_format(date_time)
    {:ok, "+1000"}

  ### GMT and UTC time zone formats

  Some valid time zones are not associated with a city of territory (country).
  Therefore they return an error for the location formats. The can producxe a
  valid result for the non-location format and the GMT format.

  #### Non-location format

    iex> Cldr.DateTime.Timezone.non_location_format("GMT")
    {:ok, "Greenwich Mean Time"}

    iex> Cldr.DateTime.Timezone.non_location_format("UTC")
    {:ok, "Coordinated Universal Time"}

  ### Location format

      iex> Cldr.DateTime.Timezone.location_format("GMT")
      {:error,
       {Cldr.DateTime.NoTerritoryForTimezone,
        "No territory was found for time zone \\"Etc/GMT\\""}}

      iex> Cldr.DateTime.Timezone.location_format("UTC")
      {:error,
       {Cldr.DateTime.NoTerritoryForTimezone,
        "No territory was found for time zone \\"Etc/UTC\\""}}

  #### GMT format

      iex> Cldr.DateTime.Timezone.gmt_format("Australia/Adelaide")
      {:ok, "GMT+09:30"}

      iex> Cldr.DateTime.Timezone.gmt_format("UTC")
      {:ok, "GMT"}

      iex> Cldr.DateTime.Timezone.gmt_format("GMT")
      {:ok, "GMT"}

  """

  alias Cldr.Locale
  alias Cldr.Substitution

  import Cldr.DateTime.Formatter, only: [is_date_time: 1, minute: 2, second: 2, h23: 2]

  @valid_types [:generic, :specific, :standard, :daylight]
  @default_type :generic

  @valid_formats [:long, :short]
  @default_format :long

  @valid_iso_formats [:short, :long, :full]
  @default_iso_format :long

  @valid_iso_types [:basic, :extended]
  @default_iso_type :basic

  @doc """
  Return the localized non-location time zone format
  for a time zone ID or a `t:DateTime.t/0`.

  ### Arguments

  * `date_time_or_zone` is any time zone ID or any
    `t:DateTime.t/0`.

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:date_time` is the date_time to be used to ascertain if the
    standard or dayligth time zone information is required. The default
    is `DateTime.utc_now/0`.

  * `:format` is either `:long` (the default) or `:short`.

  * `:type` is either `:generic` (the default), `:specific`, `:standard`
    or`:daylight`. `:specific` indicates that `:standard` or `:daylight`
    will be selected based upon the time zone of the `:date_time` option.

  ### Returns

  * `{:ok, non_location_format}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Timezone.non_location_format("Australia/Sydney")
      {:ok, "Australian Eastern Time"}

      iex> Cldr.DateTime.Timezone.non_location_format("Australia/Sydney", type: :daylight)
      {:ok, "Australian Eastern Daylight Time"}

      iex> Cldr.DateTime.Timezone.non_location_format("Asia/Shanghai")
      {:ok, "China Time"}

      iex> Cldr.DateTime.Timezone.non_location_format("Australia/Sydney", locale: :fr)
      {:ok, "heure de l’Est de l’Australie"}

      iex> Cldr.DateTime.Timezone.non_location_format("America/Phoenix")
      {:ok, "Mountain Time (Phoenix)"}

      iex> Cldr.DateTime.Timezone.non_location_format("America/Phoenix", format: :short)
      {:ok, "MT (Phoenix)"}

      iex> Cldr.DateTime.Timezone.non_location_format("Europe/Dublin")
      {:ok, "Greenwich Mean Time (Ireland)"}

      iex> Cldr.DateTime.Timezone.non_location_format("Europe/Rome", locale: :ja)
      {:ok, "中央ヨーロッパ時間（イタリア）"}

  """
  @doc since: "2.33.0"

  @spec non_location_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def non_location_format(date_time_or_zone, options \\ [])

  def non_location_format(%{time_zone: time_zone} = datetime, options) do
    options = put_new(options, :date_time, datetime)
    non_location_format(time_zone, options)
  end

  def non_location_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, time_zones} <- format.time_zones(locale),
         {:ok, meta_zones} <- format.meta_zones(locale),
         {:ok, territories} <- format.territories(locale),
         {:ok, fallback_format} <- format.zone_fallback_format(locale) do
      split_zone = split_and_downcase_zone(canonical_zone)

      zone_format =
        zone_format(get_in(time_zones, split_zone ++ [options.format]), options)

      meta_zone =
        meta_zone(canonical_zone, options.date_time)

      meta_zone_format =
        meta_zone_format(meta_zone, meta_zones, options)

      cond do
        zone_format ->
          {:ok, zone_format}

        meta_zone_format ->
          meta_zone_or_fallback_format(
            canonical_zone,
            meta_zone,
            meta_zone_format,
            fallback_format,
            locale,
            territories
          )

        options.type == :generic ->
          location_format(time_zone, options)

        true ->
          gmt_format(time_zone, options)
      end
    end
  end

  defp meta_zone_or_fallback_format(
         canonical_zone,
         meta_zone,
         meta_zone_format,
         fallback_format,
         locale,
         territories
       ) do
    preferred_zone =
      preferred_zone_for_meta_zone(meta_zone, locale)

    cond do
      preferred_zone == canonical_zone ->
        {:ok, meta_zone_format}

      preferred_zone_for_zone?(canonical_zone, meta_zone) &&
          !preferred_zone_for_locale?(canonical_zone, meta_zone, locale) ->
        fallback_with_territory(canonical_zone, meta_zone_format, fallback_format, territories)

      true ->
        fallback_with_exemplar(canonical_zone, meta_zone_format, fallback_format)
    end
  end

  # If we can't identify the territory for a zone (like with UTC) just
  # use the meta_zone_format
  defp fallback_with_territory(canonical_zone, meta_zone_format, fallback_format, territories) do
    case territory_for_zone(canonical_zone) do
      {:ok, zone_territory} ->
        territory_name = territory_name(territories, zone_territory)

        iolist =
          Substitution.substitute([meta_zone_format, territory_name], fallback_format)

        {:ok, List.to_string(iolist)}

      _other ->
        {:ok, meta_zone_format}
    end
  end

  # If we can't identify the exemplar city for a zone (like with GMT) just
  # use the meta_zone_format
  defp fallback_with_exemplar(canonical_zone, meta_zone_format, fallback_format) do
    case exemplar_city(canonical_zone) do
      {:ok, exemplar_city} ->
        iolist =
          Substitution.substitute([meta_zone_format, exemplar_city], fallback_format)

        {:ok, List.to_string(iolist)}

      _error ->
        {:ok, meta_zone_format}
    end
  end

  defp territory_name(territories, territory) do
    territory_names = Map.fetch!(territories, territory)
    territory_names[:short] || territory_names[:standard]
  end

  @doc """
  Return the localized location time zone format
  for a time zone ID or a `t:DateTime.t/0`.

  ### Arguments

  * `date_time_or_zone` is any time zone ID or any
    `t:DateTime.t/0`.

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:date_time` is the date_time to be used to ascertain if the
    standard or dayligth time zone information is required. The default
    is `DateTime.utc_now/0`.

  * `:type` is either `:generic` (the default), `:specific`, `:standard`
    or`:daylight`. `:specific` indicates that `:standard` or `:daylight`
    will be selected based upon the time zone of the `:date_time` option.

  ### Returns

  * `{:ok, non_location_format}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Timezone.location_format("Australia/Sydney")
      {:ok, "Sydney Time"}

      iex> Cldr.DateTime.Timezone.location_format("Australia/Sydney", type: :daylight)
      {:ok, "Sydney Daylight Time"}

      iex> Cldr.DateTime.Timezone.location_format("Asia/Shanghai")
      {:ok, "China Time"}

      iex> Cldr.DateTime.Timezone.location_format("America/Phoenix")
      {:ok, "Phoenix Time"}

      iex> Cldr.DateTime.Timezone.location_format("Australia/Sydney", locale: :fr)
      {:ok, "heure : Sydney"}

      iex> Cldr.DateTime.Timezone.location_format("America/Phoenix", format: :short)
      {:ok, "Phoenix Time"}

      iex> Cldr.DateTime.Timezone.location_format("Europe/Rome", locale: :ja)
      {:ok, "イタリア時間"}

      iex> Cldr.DateTime.Timezone.location_format("America/New_York", locale: :fr, type: :daylight)
      {:ok, "New York (heure d’été)"}

      iex> Cldr.DateTime.Timezone.location_format("America/New_York", locale: :fr, type: :standard)
      {:ok, "New York (heure standard)"}

  """
  @doc since: "2.33.0"

  @spec location_format(
          date_time_or_zone :: String.t() | DateTime.t(),
          options :: Keyword.t() | map()
        ) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def location_format(date_time_or_zone, options \\ [])

  def location_format(%{time_zone: time_zone} = datetime, options) do
    options = put_new(options, :date_time, datetime)
    location_format(time_zone, options)
  end

  def location_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)
    options = delete(options, :format)

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, territories} <- format.territories(locale),
         {:ok, region_format} <- format.zone_region_format(locale),
         {:ok, zone_territory} <- territory_for_zone(canonical_zone) do
      format = zone_format(region_format, options)

      case location_from_territory_and_zone(zone_territory, territories, canonical_zone) do
        {:ok, location} ->
          io_list = Substitution.substitute(location, format)
          {:ok, List.to_string(io_list)}

        error ->
          error
      end
    end
  end

  defp location_from_territory_and_zone(territory, territories, time_zone) do
    if territory_has_one_zone?(territory) || primary_zone?(time_zone) do
      territory_names = Map.fetch!(territories, territory)
      {:ok, territory_names[:short] || territory_names[:standard]}
    else
      exemplar_city(time_zone)
    end
  end

  @doc """
  Return the localized GMT time zone format
  for a time zone ID or a `t:DateTime.t/0`.

  > #### Time zones other than UTC {: .warning}
  >
  > When `date_time_or_zone` is a string and it is not `UTC` or `GMT`, a
  > [Time Zone database](https://hexdocs.pm/elixir/DateTime.html#module-time-zone-database)
  > must be configured or provided as the option `:time_zone_database`.

  ### Arguments

  * `date_time_or_zone` is any time zone ID or any
    `t:DateTime.t/0`.

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:time_zone_database` determines the time zone database to use when
    shifting time zones. Shifting time zones only occurs if the `date_time_or_zone`
    is set to a string time zone ID. The default is `Calendar.get_time_zone_database/0`.

  ### Returns

  * `{:ok, gmt_format}` or

  * `{:error, {exception, reason}}`.

  ### Notes

  * The digits of the GMT format are presented in the default number system
    of the locale defined in the locale option.

  ### Examples

      iex> Cldr.DateTime.Timezone.gmt_format(DateTime.utc_now())
      {:ok, "GMT"}

      iex> {:ok, standard_time} = DateTime.new(~D[2025-06-01], ~T[00:00:00], "Australia/Sydney")
      iex> Cldr.DateTime.Timezone.gmt_format(standard_time)
      {:ok, "GMT+10:00"}

      iex> {:ok, summer_time} = DateTime.new(~D[2025-01-01], ~T[00:00:00], "Australia/Sydney")
      iex> Cldr.DateTime.Timezone.gmt_format(summer_time)
      {:ok, "GMT+11:00"}
      iex> Cldr.DateTime.Timezone.gmt_format(summer_time, locale: :fr)
      {:ok, "UTC+11:00"}

      iex> Cldr.DateTime.Timezone.gmt_format "Canada/Newfoundland", locale: :ar
      {:ok, "غرينتش-02:30"}

      iex> {:ok, summer_time} = DateTime.new(~D[2025-06-01], ~T[00:00:00], "America/Los_Angeles")
      iex> Cldr.DateTime.Timezone.gmt_format(summer_time)
      {:ok, "GMT-07:00"}

      iex> {:ok, gmt} = DateTime.new(~D[2025-06-01], ~T[00:00:00], "GMT")
      iex> Cldr.DateTime.Timezone.gmt_format(gmt)
      {:ok, "GMT"}

  """

  @doc since: "2.33.0"

  @spec gmt_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def gmt_format(date_time_or_zone, options \\ [])

  def gmt_format(%{time_zone: time_zone} = date_time, options) do
    options = Keyword.put_new(options, :date_time, date_time)
    gmt_format(time_zone, options)
  end

  def gmt_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)
    options = delete(options, [:format, :type])

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, shifted_date_time} <-
           shift_zone(options.date_time, canonical_zone, options.time_zone_database),
         {:ok, gmt_format} <- format.gmt_format(locale),
         {:ok, gmt_zero_format} <- format.gmt_zero_format(locale),
         {:ok, hour_format} <- format.hour_format(locale),
         {:ok, formatted_hour} <- formatted_hour(shifted_date_time, hour_format) do
      time = time_map_from_zone_offset(shifted_date_time)
      {:ok, format_gmt(time, formatted_hour, gmt_format, gmt_zero_format, backend, options)}
    end
  end

  @doc false
  def gmt_tz_format(time_map, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)

    with {:ok, options} <- validate_options(options),
         {:ok, gmt_format} <- format.gmt_format(locale),
         {:ok, gmt_zero_format} <- format.gmt_zero_format(locale),
         {:ok, {positive_format, negative_format}} <- format.hour_format(locale) do
      format = if time_map.hour >= 0, do: positive_format, else: negative_format
      {:ok, time} = Time.new(abs(time_map.hour), abs(time_map.minute), time_map.second)
      {:ok, formatted_hour} = Cldr.Time.to_string(time, format: format)
      format_gmt(time, formatted_hour, gmt_format, gmt_zero_format, backend, options)
    end
  end

  defp format_gmt(%{hour: 0, minute: 0, second: 0}, _formatted_hour, _gmt_format, gmt_zero_format, _backend, _options) do
    gmt_zero_format
  end

  defp format_gmt(_time, formatted_hour, gmt_format, _gmt_zero_format, backend, options) do
    gmt_format =
      Cldr.Substitution.substitute(formatted_hour, gmt_format) |> List.to_string()

    number_system =
      Cldr.Number.System.number_system_from_locale(options.locale)

    Cldr.Number.Transliterate.transliterate(gmt_format, options.locale, number_system, backend)
  end

  @doc """
  Return the localized ISO 8601 time zone format
  for a time zone ID or a `t:DateTime.t/0`.

  > #### Time zones other than UTC {: .warning}
  >
  > When `date_time_or_zone` is a string and it is not `UTC` or `GMT`, a
  > [Time Zone database](https://hexdocs.pm/elixir/DateTime.html#module-time-zone-database)
  > must be configured or provided as the option `:time_zone_database`.

  ### Arguments

  * `date_time_or_zone` is any time zone ID or any
    `t:DateTime.t/0`.

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:format` is either `:long` (the default) or `:short`.
    * `:short` will always render the hour offset and only render the minute
      offset if it is not zero.
    * `:long` will always render the hour and minute offsets.
    * `:full` will always render the hour and minute offsets and only
      render the second offset if it is not zero. This is an extension to the
      ISO 8601 standard.

  * `:type` is either `:basic` (the default), or `:extended`.
    * `:basic` renders the time zone hour, optional minute and optional
      second with no spacing or separator between then.
    * `:extended` renders the time zone hour, optional minute and optional
      second with a `:` separator between them.

  * `:z_for_zero` is a truthy or falsy value to indicate whether or not
    to use the [Z](https://en.wikipedia.org/wiki/ISO_8601#:~:text=Z%20is%20the%20zone%20designator,30Z%22%20or%20%22T0930Z%22.)`
    indicator when the time zone offset is zero. The default is `true`.

  * `:time_zone_database` determines the time zone database to use when
    shifting time zones. Shifting time zones only occurs if the `date_time_or_zone`
    is set to a string time zone ID. The default is `Calendar.get_time_zone_database/0`.

  ### Returns

  * `{:ok, iso_format}` or

  * `{:error, {exception, reason}}`.

  ### Examples

  """
  @doc since: "2.33.0"

  @spec iso_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def iso_format(date_time_or_zone, options \\ [])

  def iso_format(%{time_zone: time_zone} = date_time, options) do
    options = Keyword.put_new(options, :date_time, date_time)
    iso_format(time_zone, options)
  end

  def iso_format(time_zone, options) when is_binary(time_zone) do
    with {:ok, options} <- validate_iso_options(options),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, shifted_date_time} <-
             shift_zone(options.date_time, canonical_zone, options.time_zone_database) do
      {hour, minute, second} = time_from_zone_offset(shifted_date_time)
      time = %{hour: hour, minute: abs(minute), second: second}
      {:ok, iso_format_type(time, options.type, options.format, options.z_for_zero)}
    end
  end

  # Z format

  def iso_format_type(%{hour: 0, minute: 0, second: 0}, _type, _format, z_for_zero) when z_for_zero do
    "Z"
  end

  # Basic format

  def iso_format_type(%{hour: hour, minute: 0} = time, :basic, :short, _z_for_zero) do
    sign(hour) <> h23(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute} = time, :basic, :short, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute} = time, :basic, :long, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute, second: 0} = time, :basic, :full, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute, second: _second} = time, :basic, :full, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> minute(time, 2) <> second(time, 2)
  end

  # Extended format

  def iso_format_type(%{hour: hour, minute: 0} = time, :extended,  :short, _z_for_zero) do
    sign(hour) <> h23(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute} = time, :extended,  :short, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute} = time, :extended, :long, _z_for_zero) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute, second: 0} = time, :extended, :full,  _z_for_zero) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2)
  end

  def iso_format_type(%{hour: hour, minute: _minute, second: _second} = time, :extended, :full,  _z_for_zero) do
    sign(hour) <> h23(time, 2) <> ":" <> minute(time, 2) <> ":" <> second(time, 2)
  end

  defp sign(number) when number >= 0, do: "+"
  defp sign(_number), do: "-"

  defp shift_zone(%{time_zone: time_zone} = date_time, time_zone, _time_zone_database) do
    {:ok, date_time}
  end

  defp shift_zone(date_time, time_zone, time_zone_database) do
    DateTime.shift_zone(date_time, time_zone, time_zone_database)
  end

  defp formatted_hour(date_time, {positive_format, negative_format}) do
    offset = date_time.utc_offset + date_time.std_offset
    format = if offset >= 0, do: positive_format, else: negative_format

    case time_from_zone_offset(date_time) do
      {hour, minute, second} ->
        {:ok, time} = Time.new(abs(hour), abs(minute), second)
        Cldr.Time.to_string(time, format: format)

      error ->
        error
    end
  end

  @doc """
  Return the localized exemplar City for a
  time zone.

  The examplar city is, by default, the last
  segment of a time zone ID. For some time zones
  there is an explicit localized exemplar which,
  if it exists, is returned instead.

  ### Arguments

  * `date_time_or_zone` is any time zone ID or any
    `t:DateTime.t/0`.

  * `options` is a keyword list of options.

  ### Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  ### Returns

  * `{:ok, exemplar_city}` or

  * `{:error, {exception, reason}}`.

  ### Examples

    iex> Cldr.DateTime.Timezone.exemplar_city("Australia/Sydney")
    {:ok, "Sydney"}

    iex> Cldr.DateTime.Timezone.exemplar_city("Europe/Kiev")
    {:ok, "Kyiv"}

    iex> Cldr.DateTime.Timezone.exemplar_city("America/Indiana/Knox")
    {:ok, "Knox, Indiana"}

    iex> Cldr.DateTime.Timezone.exemplar_city("Europe/Kiev", locale: :ja)
    {:ok, "キーウ"}

    iex> Cldr.DateTime.Timezone.exemplar_city("Etc/Unknown")
    {:ok, "Unknown City"}

    iex> Cldr.DateTime.Timezone.exemplar_city("Etc/UTC")
    {:error, {Cldr.DateTime.UnknownExemplarCity, "No exemplar city is known for \\"Etc/UTC\\""}}

    iex> Cldr.DateTime.Timezone.exemplar_city("Etc/GMT+5")
    {:error, {Cldr.DateTime.UnknownExemplarCity, "No exemplar city is known for \\"Etc/GMT+5\\""}}

    iex> Cldr.DateTime.Timezone.exemplar_city("Europe/Frankenstein")
    {:error,
     {Cldr.UnknownTimezoneError, "Unknown time zone \\"Europe/Frankenstein\\""}}

  """
  @doc since: "2.33.0"

  @spec exemplar_city(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def exemplar_city(date_time_or_zone, options \\ [])

  def exemplar_city(%{time_zone: time_zone}, options) do
    exemplar_city(time_zone, options)
  end

  def exemplar_city(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)

    with {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, time_zones} <- format.time_zones(locale) do
      resolve_exemplar_city(canonical_zone, time_zones)
    end
  end

  @doc """
  Returns the canonical time zone name for a given time
  zone identifier.

  """
  @doc since: "2.33.0"
  def canonical_time_zone(time_zone) do
    case Map.fetch(canonical_time_zones(), time_zone) do
      {:ok, time_zone} -> {:ok, time_zone}
      :error -> {:error, {Cldr.UnknownTimezoneError, "Unknown time zone #{inspect(time_zone)}"}}
    end
  end

  @doc """
  Converts the time zone offset of a `Time` or `DateTime` into
  seconds.

  """
  def time_from_zone_offset(%{utc_offset: utc_offset, std_offset: std_offset}) do
    offset = utc_offset + std_offset

    hours = div(offset, 3600)
    minutes = div(offset - hours * 3600, 60)
    seconds = offset - hours * 3600 - minutes * 60
    {hours, minutes, seconds}
  end

  def time_from_zone_offset(time) do
    {:error, "Expected a map with :utc_offset and :std_offset fields. Found #{inspect time}"}
  end

  @doc false
  def time_map_from_zone_offset(offset) do
    {hours,  minutes, seconds} = time_from_zone_offset(offset)
    %{hour: hours, minute: minutes, second: seconds}
  end

  @doc """
  Returns the metazone data.

  """
  @doc since: "2.33.0"
  @meta_zones Cldr.Config.metazones()
  def meta_zones do
    @meta_zones
  end

  @doc """
  Returns the mapping of time zone short
  IDs to metazone data.

  """
  @doc since: "2.33.0"
  @meta_zone_ids Cldr.Config.metazone_ids()
  def meta_zone_ids do
    @meta_zone_ids
  end

  @doc """
  Returns the mapping of a metazone to
  a time zone long ID.

  """
  @doc since: "2.33.0"
  @meta_zone_mapping Cldr.Config.metazone_mapping()
  def meta_zone_mapping do
    @meta_zone_mapping
  end

  @doc """
  Returns the primary time zone for certain
  territories.

  """
  @doc since: "2.33.0"
  @primary_zones Cldr.Config.primary_zones()
  def primary_zones do
    @primary_zones
  end

  @doc """
  Returns the canonical time zone mapping.

  """
  @doc since: "2.33.0"
  @canonical_timezones Cldr.Config.canonical_timezones()
  def canonical_time_zones do
    @canonical_timezones
  end

  @doc false
  def unknown_city(options \\ []) do
    exemplar_city("Etc/Unknown", options)
  end

  defp resolve_exemplar_city("Etc/UTC" = time_zone, _time_zones) do
    {:error, no_exemplar_city_error(time_zone)}
  end

  defp resolve_exemplar_city("Etc/GMT" <> _rest = time_zone, _time_zones) do
    {:error, no_exemplar_city_error(time_zone)}
  end

  defp resolve_exemplar_city(time_zone, time_zones) do
    zone_segments = split_and_downcase_zone(time_zone)

    exemplar_city =
      case get_in(time_zones, zone_segments) do
        nil -> examplar_city_from_segments(zone_segments)
        time_zone -> time_zone[:exemplar_city] || examplar_city_from_segments(zone_segments)
      end

    {:ok, exemplar_city}
  end

  def no_exemplar_city_error(time_zone) do
    {Cldr.DateTime.UnknownExemplarCity, "No exemplar city is known for #{inspect(time_zone)}"}
  end

  defp preferred_zone_for_zone?(time_zone, meta_zone) do
    case territory_for_zone(time_zone) do
      {:ok, territory} ->
        time_zone == preferred_zone_for_territory(territory, meta_zone)

      _other ->
        false
    end
  end

  defp preferred_zone_for_locale?(time_zone, meta_zone, locale) do
    territory = Cldr.Locale.territory_from_locale(locale)
    time_zone == preferred_zone_for_territory(territory, meta_zone)
  end

  defp preferred_zone_for_territory(territory, meta_zone) do
    case Map.get(meta_zone_mapping(), meta_zone) do
      nil -> nil
      mapping -> Map.get(mapping, territory) || Map.get(mapping, :"001")
    end
  end

  defp preferred_zone_for_meta_zone(meta_zone, locale) do
    territory = Locale.territory_from_locale(locale)

    case Map.get(meta_zone_mapping(), meta_zone) do
      nil -> nil
      mapping -> Map.get(mapping, territory) || Map.get(mapping, :"001")
    end
  end

  defp territory_for_zone(time_zone) do
    case Map.fetch(Cldr.Timezone.territories_by_timezone(), time_zone) do
      {:ok, territory} ->
        {:ok, territory}

      :error ->
        {:error,
         {
           Cldr.DateTime.NoTerritoryForTimezone,
           "No territory was found for time zone #{inspect(time_zone)}"
         }}
    end
  end

  defp territory_has_one_zone?(territory) do
    length(Map.get(Cldr.Timezone.timezones_by_territory(), territory)) == 1
  end

  defp primary_zone?(time_zone) do
    Map.has_key?(primary_zones(), time_zone)
  end

  # If there is no daylight field then we can substitute fall back
  # first to :generic and secondly to :standard.

  # Otherwise if the generic type is needed, but not available,
  # and the offset and daylight offset do not change within 184
  # day +/- interval around the exact formatted time, use the standard type.
  # Note: 184 is the smallest number that is at least 6 months AND the
  # smallest number that is more than 1/2 year (Gregorian)

  defp zone_format(nil, _options) do
    nil
  end

  defp zone_format(formats, %{date_time: date_time, type: :specific} = options) do
    type = if date_time.std_offset == 0, do: :standard, else: :daylight
    zone_format(formats, Map.put(options, :type, type))
  end

  defp zone_format(formats, options) do
    cond do
      !is_map_key(formats, :daylight) ->
        Map.get(formats, options.type) ||
          Map.get(formats, :generic) ||
          Map.get(formats, :standard)

      options.type == :generic && is_map_key(formats, :generic) ->
        Map.get(formats, :generic)

      options.type == :generic ->
        if no_offset_change_within_184_days?(options.date_time) do
          Map.get(formats, :standard)
        end

      true ->
        Map.get(formats, options.type)
    end
  end

  defp meta_zone(time_zone, date_time) do
    case get_in(meta_zones(), split_zone(time_zone)) do
      nil -> nil
      [[meta_zone, nil, nil]] -> meta_zone
      list_of_meta_zones -> find_meta_zone(list_of_meta_zones, date_time)
    end
  end

  defp meta_zone_format(nil, _meta_zones, _options) do
    nil
  end

  defp meta_zone_format(meta_zone, meta_zones, options) do
    if meta_zone = Map.get(meta_zones, normalize_meta_zone(meta_zone)) do
      Map.get(meta_zone, options.format)
      |> zone_format(options)
    end
  end

  # One metazone is "Australia_CentralWestern" but the
  # metazone is actually "australia_central_eestern".
  # Perhaps a data error. We work around it for now.
  defp normalize_meta_zone(meta_zone) do
    meta_zone
    |> Macro.underscore()
    |> String.replace("__", "_")
    |> String.downcase()
  end

  # Note that meta zones are in descending date time order
  # with the most recent meta zone first in the list.
  defp find_meta_zone(list_of_meta_zones, date_time) do
    Enum.reduce_while(list_of_meta_zones, nil, fn
      [meta_zone, nil, nil], _acc ->
        {:halt, meta_zone}

      [meta_zone, from, nil], acc ->
        if DateTime.compare(date_time, from) in [:gt, :eq] do
          {:halt, meta_zone}
        else
          {:cont, acc}
        end

      [meta_zone, nil, to], acc ->
        if DateTime.compare(date_time, to) in [:lt, :eq] do
          {:halt, meta_zone}
        else
          {:cont, acc}
        end

      [meta_zone, from, to], acc ->
        if DateTime.compare(date_time, from) in [:gt, :eq] &&
             DateTime.compare(date_time, to) in [:lt, :eq] do
          {:halt, meta_zone}
        else
          {:cont, acc}
        end
    end)
  end

  defp no_offset_change_within_184_days?(date_time) do
    plus_184 = DateTime.shift(date_time, day: 184)
    minus_184 = DateTime.shift(date_time, day: -184)

    date_time.utc_offset == plus_184.utc_offset &&
      date_time.utc_offset == minus_184.utc_offset &&
      date_time.std_offset == plus_184.std_offset &&
      date_time.std_offset == minus_184.std_offset
  end

  defp split_zone(time_zone) do
    time_zone
    |> String.split("/")
  end

  defp split_and_downcase_zone(time_zone) do
    time_zone
    |> String.downcase()
    |> split_zone()
  end

  defp examplar_city_from_segments(zone_segments) do
    zone_segments
    |> Enum.reverse()
    |> hd()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp validate_options(options) when is_map(options) do
    {:ok, options}
  end

  defp validate_options(options) when is_list(options) do
    options =
      default_options()
      |> Keyword.merge(options)

    options =
      Enum.reduce_while(options, options, fn
        {:locale, _locale}, acc ->
          {:cont, acc}

        {:backend, _backend}, acc ->
          {:cont, acc}

        {:type, type}, acc when type in @valid_types ->
          {:cont, acc}

        {:type, type}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid type #{inspect(type)}. Valid types are #{inspect(@valid_types)}"
            }}}

        {:format, format}, acc when format in @valid_formats ->
          {:cont, acc}

        {:format, format}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid format #{inspect(format)}. Valid format are #{inspect(@valid_formats)}"
            }}}

        {:date_time, date_time}, acc when is_date_time(date_time) ->
          {:cont, acc}

        {:date_time, datetime}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid date_time #{inspect(datetime)}"
            }}}

        {:time_zone_database, _number_system}, acc ->
          {:cont, acc}

        {option, _}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid option #{inspect(option)}. Valid options are :date_time, :type, :format, :locale and :backend"
            }}}
      end)

    case options do
      {:error, reason} ->
        {:error, reason}

      options ->
        {:ok, Map.new(options)}
    end
  end

  defp validate_iso_options(options) when is_map(options) do
    {:ok, options}
  end

  defp validate_iso_options(options) when is_list(options) do
    options =
      default_iso_options()
      |> Keyword.merge(options)

    options =
      Enum.reduce_while(options, options, fn
        {:type, type}, acc when type in @valid_iso_types ->
          {:cont, acc}

        {:type, type}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid type #{inspect(type)}. Valid format are #{inspect(@valid_iso_types)}"
            }}}

        {:format, format}, acc when format in @valid_iso_formats ->
          {:cont, acc}

        {:format, format}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid format #{inspect(format)}. Valid format are #{inspect(@valid_iso_formats)}"
            }}}

        {:z_for_zero, _z_for_zero}, acc ->
          {:cont, acc}

        {:date_time, date_time}, acc when is_date_time(date_time) ->
          {:cont, acc}

        {:date_time, datetime}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid date_time #{inspect(datetime)}"
            }}}

        {:time_zone_database, _number_system}, acc ->
          {:cont, acc}

        {option, _}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid option #{inspect(option)}. Valid options are :date_time, :format"
            }}}
      end)

    case options do
      {:error, reason} ->
        {:error, reason}

      options ->
        {:ok, Map.new(options)}
    end
  end

  defp put_new(options, key, value) when is_list(options), do: Keyword.put_new(options, key, value)
  defp put_new(options, key, value) when is_map(options), do: Map.put_new(options, key, value)

  defp delete(options, keys) when is_list(options) and is_list(keys) do
    Enum.reduce(keys, options, fn key, acc -> Keyword.delete(acc, key) end)
  end

  defp delete(options, key) when is_list(options), do: Keyword.delete(options, key)
  defp delete(options, key) when is_map(options), do: Map.delete(options, key)

  defp default_options do
    [
      type: @default_type,
      format: @default_format,
      locale: Cldr.get_locale(),
      date_time: DateTime.utc_now(),
      time_zone_database: Calendar.get_time_zone_database()
    ]
  end

  defp default_iso_options do
    [
      format: @default_iso_format,
      type: @default_iso_type,
      date_time: DateTime.utc_now(),
      z_for_zero: true,
      time_zone_database: Calendar.get_time_zone_database()
    ]
  end
end
