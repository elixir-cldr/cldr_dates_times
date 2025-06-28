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

  @valid_types [:generic, :standard, :daylight]
  @default_type :generic

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
    zone_segments = split_zone_segments(time_zone)

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

  defp split_zone_segments(time_zone) do
    time_zone
    |> String.downcase()
    |> String.split("/")
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
  @metazones Cldr.Config.metazones()
  def metazones do
    @metazones
  end

  @doc """
  Returns the mapping of time zone short
  IDs to metazone data.

  """
  @doc since: "2.33.0"
  @metazone_ids Cldr.Config.metazone_ids()
  def metazone_ids do
    @metazone_ids
  end

  @doc """
  Returns the mapping of a metazone to
  a time zone long ID.

  """
  @doc since: "2.33.0"
  @metazone_mapping Cldr.Config.metazone_mapping()
  def metazone_mapping do
    @metazone_mapping
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

  defp validate_type(type) when type in @valid_types do
    {:ok, type}
  end

  defp validate_type(other) do
    {:error, {ArgumentError, "Invalid time zone type #{inspect other}"}}
  end

end
