defmodule Cldr.DateTime.TimezoneTest do
  use ExUnit.Case, async: true

  alias Cldr.DateTime.Timezone

  test "Exemplar City when timezone data exists but has no exemplar field" do
    assert {:ok, "Honolulu"} = Timezone.exemplar_city("Pacific/Honolulu")
  end

  test "Asia/Shanghai resolves to China (country level) since thats a primary zone" do
    assert {:ok, "China Time"} = Timezone.location_format("Asia/Shanghai")
  end

  test "When a country has only one zone" do
    assert {:ok, "Italy Daylight Time"} =
             Timezone.location_format("Europe/Rome", type: :daylight)

    assert {:ok, "Central European Summer Time (Italy)"} =
             Timezone.non_location_format("Europe/Rome", type: :daylight)
  end

  test "When a country has multiple zones" do
    assert {:ok, "Buenos Aires Time"} = Timezone.location_format("America/Buenos_Aires")
  end

  test "Zones that need canonicalization" do
    assert {:ok, "Central European Time (Belgium)"} = Timezone.non_location_format("CET")
    assert {:ok, "Belgium Time"} = Timezone.location_format("CET")
  end

  test "When with a datetime argument" do
    assert {:ok, "Coordinated Universal Time"} =
             Timezone.non_location_format(DateTime.utc_now())

    assert Timezone.location_format(DateTime.utc_now()) ==
             {:error,
              {Cldr.DateTime.NoTerritoryForTimezone,
               "No territory was found for time zone \"Etc/UTC\""}}
  end
end
