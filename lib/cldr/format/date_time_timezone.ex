defmodule Cldr.DateTime.Timezone do
  @moduledoc """
  Functions to format time zone IDs, including the time zone field
  of a `t:DateTime.t/0`.

  """

  alias Cldr.Locale
  alias Cldr.Substitution

  import Cldr.DateTime.Formatter, only: :macros

  @valid_types [:generic, :standard, :daylight]
  @default_type :generic

  @valid_formats [:long, :short]
  @default_format :long

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

  * `:format` is either `:long` (the default) or `:short`.

  * `:type` is either `:generic` (the default), `:standard` or `:daylight`.

  ### Returns

  * `{:ok, non_location_format}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Timezone.non_location_format("Australia/Sydney")
      {:ok, "Australian Eastern Time"}

      iex> Cldr.DateTime.Timezone.non_location_format("America/Phoenix")
      {:ok, "Mountain Time"}

      iex> Cldr.DateTime.Timezone.non_location_format("Australia/Sydney", locale: :fr)
      {:ok, "heure de l’Est de l’Australie"}

      iex> Cldr.DateTime.Timezone.non_location_format("America/Phoenix", format: :short)
      {:ok, "MT"}

      iex> Cldr.DateTime.Timezone.non_location_format("Europe/Rome", locale: :ja)
      {:ok, "中央ヨーロッパ時間"}

  """
  @doc since: "2.33.0"

  @spec non_location_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def non_location_format(date_time_or_zone, options \\ [])

  def non_location_format(%{time_zone: time_zone} = datetime, options) do
    options = put_new(options, :datetime, datetime)
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
         {:ok, fallback_format} <- format.zone_fallback_format(locale) do
      split_zone = split_and_downcase_zone(canonical_zone)

      zone_format =
        zone_format(get_in(time_zones, split_zone ++ [options.format]), options)

      meta_zone =
        meta_zone(time_zone, options.date_time)

      meta_zone_name =
        meta_zone_name(meta_zone, meta_zones, options)

      preferred_zone =
        preferred_zone_for_meta_zone(meta_zone, locale)

      cond do
        zone_format ->
          {:ok, zone_format}

        meta_zone_name ->
          {:ok, meta_zone_name}

        preferred_zone == time_zone ->
          {:ok, zone_format}

        zone_format && preferred_zone_for_territory?(preferred_zone) &&
            !preferred_zone_for_locale?(preferred_zone, locale) ->
          territory = Cldr.Locale.territory_from_locale(locale)
          iolist = Substitution.substitute([zone_format, to_string(territory)], fallback_format)
          {:ok, List.to_string(iolist)}

        options.type == :generic ->
          location_format(time_zone, options)

        options.type in [:standard, :daylight] ->
          gmt_format(time_zone, options)
      end
    end
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

  * `:format` is either `:long` (the default) or `:short`.

  * `:type` is either `:generic` (the default), `:standard` or `:daylight`.

  ### Returns

  * `{:ok, non_location_format}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.DateTime.Timezone.location_format("Australia/Sydney")
      {:ok, "Sydney Time"}

      iex> Cldr.DateTime.Timezone.location_format("America/Phoenix")
      {:ok, "Phoenix Time"}

      iex> Cldr.DateTime.Timezone.location_format("Australia/Sydney", locale: :fr)
      {:ok, "heure : Sydney"}

      iex> Cldr.DateTime.Timezone.location_format("America/Phoenix", format: :short)
      {:ok, "Phoenix Time"}

      iex> Cldr.DateTime.Timezone.location_format("Europe/Rome", locale: :ja)
      {:ok, "IT時間"}

      iex> Cldr.DateTime.Timezone.location_format("America/New_York", locale: :fr, type: :daylight)
      {:ok, "New York (heure d’été)"}

      iex> Cldr.DateTime.Timezone.location_format("America/New_York", locale: :fr, type: :standard)
      {:ok, "New York (heure standard)"}

  """
  @doc since: "2.33.0"

  @spec location_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def location_format(date_time_or_zone, options \\ [])

  def location_format(%{time_zone: time_zone} = datetime, options) do
    options = put_new(options, :datetime, datetime)
    location_format(time_zone, options)
  end

  def location_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)
    options = delete(options, :format)

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, region_format} <- format.zone_region_format(locale) do
      zone_territory = territory_for_zone(canonical_zone)
      format = zone_format(region_format, options)

      location =
        if territory_has_one_zone?(zone_territory) || primary_zone?(canonical_zone) do
          territory = territory_for_zone(time_zone)
          to_string(territory)
        else
          {:ok, exemplar_city} = exemplar_city(canonical_zone)
          exemplar_city
        end

      io_list = Substitution.substitute(location, format)
      {:ok, List.to_string(io_list)}
    end
  end

  @doc since: "2.33.0"

  @spec gmt_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def gmt_format(date_time_or_zone, options \\ [])

  def gmt_format(%{time_zone: time_zone} = datetime, options) do
    options = Keyword.put_new(options, :datetime, datetime)
    gmt_format(time_zone, options)
  end

  def gmt_format(time_zone, _options) when is_binary(time_zone) do
    {:ok, "Not done yet"}
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

  def time_from_zone_offset(other) do
    Cldr.DateTime.Formatter.error_return(other, "x", [:utc_offset])
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

  defp preferred_zone_for_territory(territory) do
    zones =
      Cldr.Timezone.timezones_by_territory()
      |> Map.fetch!(territory)

    case zones do
      [%{aliases: [time_zone | _rest]}] -> time_zone
      _other -> nil
    end
  end

  defp preferred_zone_for_territory?(time_zone) do
    territory = territory_for_zone(time_zone)
    preferred_zone_for_territory(territory)
  end

  defp preferred_zone_for_locale?(time_zone, locale) do
    territory = Cldr.Locale.territory_from_locale(locale)
    time_zone == preferred_zone_for_territory(territory)
  end

  defp territory_for_zone(time_zone) do
    Map.fetch!(Cldr.Timezone.territories_by_timezone(), time_zone)
  end

  defp territory_has_one_zone?(territory) do
    length(Map.get(Cldr.Timezone.timezones_by_territory(), territory)) == 1
  end

  defp primary_zone?(time_zone) do
    Map.has_key?(primary_zones(), time_zone)
  end

  defp preferred_zone_for_meta_zone(meta_zone, locale) do
    territory = Locale.territory_from_locale(locale)

    case Map.get(meta_zone_mapping(), meta_zone) do
      nil -> nil
      mapping -> Map.get(mapping, territory) || Map.get(mapping, :"001")
    end
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

  defp meta_zone_name(nil, _meta_zones, _options) do
    nil
  end

  defp meta_zone_name(meta_zone, meta_zones, options) do
    meta_zones
    |> Map.get(String.downcase(meta_zone))
    |> Map.get(options.format)
    |> zone_format(options)
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

        {option, _}, _acc ->
          {:halt,
           {:error,
            {
              ArgumentError,
              "Invalid option #{inspect(option)}. Valid options are :type and :format"
            }}}
      end)

    case options do
      {:error, reason} -> {:error, reason}
      options -> {:ok, Map.new(options)}
    end
  end

  defp put_new(options, key, value) when is_list(options), do: Keyword.put_new(options, key, value)
  defp put_new(options, key, value) when is_map(options), do: Map.put_new(options, key, value)

  defp delete(options, key) when is_list(options), do: Keyword.delete(options, key)
  defp delete(options, key) when is_map(options), do: Map.delete(options, key)

  defp default_options do
    [
      type: @default_type,
      format: @default_format,
      locale: Cldr.get_locale(),
      date_time: DateTime.utc_now()
    ]
  end
end
