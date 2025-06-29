defmodule Cldr.DateTime.TimezoneTest do
  use ExUnit.Case, async: true

  alias Cldr.DateTime.Timezone
  import Cldr.DateTime.TestHelpers

  @test_locales [:en, :ja, :ar, :fr, :de, :it]

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

  for {zone, _} <- Cldr.Timezone.territories_by_timezone(),
      locale <- @test_locales,
      non_location_zones(zone) do
    test "Non-location format for #{inspect(zone)} in locale #{inspect(locale)}" do
      assert {:ok, _} =
               Timezone.non_location_format(unquote(zone),
                 format: :long,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.non_location_format(unquote(zone),
                 format: :short,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.non_location_format(unquote(zone),
                 type: :standard,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.non_location_format(unquote(zone),
                 type: :daylight,
                 locale: unquote(locale)
               )
    end

    test "Location format for #{inspect(zone)} in locale #{inspect(locale)}" do
      assert {:ok, _} =
               Timezone.location_format(unquote(zone),
                 format: :long,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.location_format(unquote(zone),
                 format: :short,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.location_format(unquote(zone),
                 type: :standard,
                 locale: unquote(locale)
               )

      assert {:ok, _} =
               Timezone.location_format(unquote(zone),
                 type: :daylight,
                 locale: unquote(locale)
               )
    end
  end
end
