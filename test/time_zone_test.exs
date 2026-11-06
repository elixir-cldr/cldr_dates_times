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

  # The root locale has no metazone names. These raised a BadMapError
  # when meta_zones/1 returned nil for it (#75).
  describe "the :und locale" do
    test "meta_zones/1 returns an empty map" do
      assert MyApp.Cldr.DateTime.Format.meta_zones(:und) == {:ok, %{}}
    end

    test "non_location_format/2 falls back to the exemplar city" do
      assert {:ok, "New York"} =
               Timezone.non_location_format("America/New_York", locale: :und)

      assert {:ok, "New York"} =
               Timezone.non_location_format("America/New_York", locale: :und, type: :generic)
    end

    test "time zone name formats fall back to GMT and location formats" do
      date_time = DateTime.new!(~D[2026-11-07], ~T[10:00:00], "America/New_York")

      assert {:ok, "10:00 GMT-05:00"} =
               Cldr.DateTime.to_string(date_time, format: "HH:mm zzzz", locale: :und)

      assert {:ok, "10:00 GMT-05:00"} =
               Cldr.DateTime.to_string(date_time, format: "HH:mm z", locale: :und)

      assert {:ok, "10:00 New York"} =
               Cldr.DateTime.to_string(date_time, format: "HH:mm vvvv", locale: :und)

      assert {:ok, "10:00 New York"} =
               Cldr.DateTime.to_string(date_time, format: "HH:mm v", locale: :und)
    end
  end
end
