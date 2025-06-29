defmodule Cldr.DateTime.Timezone do
  @moduledoc false

#   Type Fallback
#
#   When a specified type (generic, standard, daylight) does not exist:
#
#   If the daylight type does not exist, then the metazone doesn’t require daylight support. For
#   all three types:
#     If the generic type exists, use it.
#     Otherwise if the standard type exists, use it.
#
#   Otherwise if the generic type is needed, but not available, and the offset and daylight offset
#   do not change within 184 day +/- interval around the exact formatted time, use the standard
#   type.
#     Example: "Mountain Standard Time" for Phoenix
#     Note: 184 is the smallest number that is at least 6 months AND the smallest number that is
#     more than 1/2 year (Gregorian).

  alias Cldr.Locale
  import Cldr.DateTime.Formatter, only: :macros

  @valid_types [:generic, :standard, :daylight]
  @default_type :generic

  @valid_formats [:long, :short]
  @default_format :long

  @doc since: "2.33.0"

  @spec non_location_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t()) ::
    {:ok, String.t()} | {:error, {module, String.t()}}

  def non_location_format(date_time_or_zone, options \\ [])

  def non_location_format(%{time_zone: time_zone} = datetime, options) do
    options = Keyword.put_new(options, :datetime, datetime)
    non_location_format(time_zone, options)
  end

  def non_location_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, time_zones} <- format.time_zones(locale),
         {:ok, meta_zones} <- format.meta_zones(locale) do
      split_zone = split_and_downcase_zone(canonical_zone)

      zone_name =
        zone_name(get_in(time_zones, split_zone), options)

      meta_zone =
        meta_zone(time_zone, options.date_time)

      meta_zone_name =
        if meta_zone, do:
          meta_zones
          |> Map.get(String.downcase(meta_zone))
          |> zone_name(options)

      cond do
        zone_name ->
          zone_name

        meta_zone_name ->
          meta_zone_name

        meta_zone ->
          preferred_zone = preferred_zone_for_meta_zone(meta_zone, locale)

          if preferred_zone == time_zone do
            zone_name
          else
            {:ok, fallback_format} = format.zone_fallback_format(locale)
          end

        options.type == :generic ->
          location_format(time_zone, options)

        options.type in [:standard, :daylight] ->
          # gmt_format(time_zone, options)
      end
    end
  end

  @doc since: "2.33.0"

  @spec location_format(date_time_or_zone :: String.t() | DateTime.t(), options :: Keyword.t()) ::
    {:ok, String.t()} | {:error, {module, String.t()}}

  def location_format(date_time_or_zone, options \\ [])

  def location_format(%{time_zone: time_zone} = datetime, options) do
    options = Keyword.put_new(options, :datetime, datetime)
    location_format(time_zone, options)
  end

  def location_format(time_zone, options) when is_binary(time_zone) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    format = Module.concat(backend, DateTime.Format)

    with {:ok, options} <- validate_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, canonical_zone} <- canonical_time_zone(time_zone),
         {:ok, region_format} <- format.zone_region_format(locale) do
      territory = Cldr.Locale.territory_from_locale(locale)
      format = Map.fetch!(region_format, options.type)

      location =
        if territory_has_one_zone?(territory) || primary_zone?(canonical_zone) do
          territory = territory_for_zone(time_zone)
          to_string(territory)
        else
          {:ok, exemplar_city} = exemplar_city(canonical_zone)
          exemplar_city
        end

      io_list = Cldr.Substitution.substitute(location, format)
      {:ok, List.to_string(io_list)}
    end
  end

  defp territory_for_zone(time_zone) do
    Map.fetch!(Cldr.Timezone.territories_by_timezone(), time_zone)
  end

  defp territory_has_one_zone?(territory) do
    Map.get(Cldr.Timezone.timezones_by_territory(), territory) == 1
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

  defp zone_name(nil, _options) do
    nil
  end

  # If there is no daylight field then we can substitute fall back
  # first to :generic and secondly to :standard
  defp zone_name(zone, options) when not is_map_key(zone, :daylight) do
    get_in(zone, [options.format, options.type]) ||
      get_in(zone, [options.format, :generic]) ||
      get_in(zone, [options.format, :standard])
  end

  # Otherwise if the generic type is needed, but not available,
  # and the offset and daylight offset do not change within 184
  # day +/- interval around the exact formatted time, use the standard type.
  # Note: 184 is the smallest number that is at least 6 months AND the
  # smallest number that is more than 1/2 year (Gregorian)
  defp zone_name(zone, %{type: :generic} = options) do
    if no_offset_change_within_184_days?(options.date_time) do
      get_in(zone, [options.format, :standard])
    end
  end

  defp zone_name(zone, options) do
    get_in(zone, [options.format, options.type])
  end

  def meta_zone(time_zone, date_time \\ DateTime.utc_now()) do
    case get_in(meta_zones(), split_zone(time_zone)) do
      nil -> nil
      [[meta_zone, nil, nil]] -> meta_zone
      list_of_meta_zones -> find_meta_zone(list_of_meta_zones, date_time)
    end
  end

  # Note that meta zones are in descending date time order
  # with the most recent meta zone first in the list.
  defp find_meta_zone(list_of_meta_zones, date_time) do
    Enum.reduce_while list_of_meta_zones, nil, fn
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
    end
  end

  defp no_offset_change_within_184_days?(date_time) do
    plus_184 = DateTime.shift(date_time, day: 184)
    minus_184 = DateTime.shift(date_time, day: -184)

    date_time.utc_offset == plus_184.utc_offset == minus_184.utc_offset &&
      date_time.std_offset == plus_184.std_offset == minus_184.std_offset
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
    {Cldr.DateTime.UnknownExemplarCity, "No exemplar city is known for #{inspect time_zone}"}
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

  @doc """
  Returns the canonical time zone name for a given time
  zone identifier.

  """
  @doc since: "2.33.0"
  def canonical_time_zone(time_zone) do
    case Map.fetch(canonical_time_zones(), time_zone) do
      {:ok, time_zone} -> {:ok, time_zone}
      :error -> {:error, {Cldr.UnknownTimezoneError, "Unknown time zone #{inspect time_zone}"}}
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

  defp validate_options(options) do
    options =
      default_options()
      |> Keyword.merge(options)

    Enum.reduce_while(options, options, fn
      {:type, type}, acc when type in @valid_types ->
        {:cont, acc}

      {:type, type}, _acc ->
        {:halt, {:error, {
          ArgumentError, "Invalid type #{inspect type}. Valid types are #{inspect @valid_types}"}}}

      {:format, format}, acc when format in @valid_formats ->
        {:cont, acc}

      {:format, format}, _acc ->
        {:halt, {:error, {
          ArgumentError, "Invalid format #{inspect format}. Valid format are #{inspect @valid_formats}"}}}

      {:date_time, date_time}, acc when is_date_time(date_time) ->
        {:cont, acc}

      {:date_time, datetime}, _acc ->
        {:halt, {:error, {
          ArgumentError, "Invalid date_time #{inspect datetime}"}}}

      {option, _}, _acc ->
        {:halt, {:error, {
          ArgumentError, "Invalid option #{inspect option}. Valid options are :type and :format"}}}
    end)

    case options do
      {:error, reason} -> {:error, reason}
      options -> {:ok, Map.new(options)}
    end
  end

  defp default_options do
    [
      type: @default_type,
      format: @default_format,
      date_time: DateTime.utc_now()
    ]
  end
end
