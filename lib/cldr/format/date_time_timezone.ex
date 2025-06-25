defmodule Cldr.DateTime.Timezone do
  @moduledoc false

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
end
