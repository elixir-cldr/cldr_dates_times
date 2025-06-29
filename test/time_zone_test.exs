defmodule Cldr.DateTime.TimezoneTest do
  use ExUnit.Case, async: true

  @test_locales [:en, :ja, :ar, :fr, :de, :it]

  test "Exemplar City when timezone data exists but has no exemplar field" do
    assert {:ok, "Honolulu"} = Cldr.DateTime.Timezone.exemplar_city("Pacific/Honolulu")
  end

  test "Asia/Shanghai resolves to China (country level) since thats a primary zone" do

  end

  for {zone, _} <- Cldr.Timezone.territories_by_timezone(),
      locale <- @test_locales,
      !String.starts_with?(zone, "Etc") && !String.starts_with?(zone, "GMT") && zone != "Greenwich" do
    test "Non-location format for #{inspect zone} in locale #{inspect locale}" do
      assert {:ok, _} =
        Cldr.DateTime.Timezone.non_location_format(unquote(zone), format: :long, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.non_location_format(unquote(zone), format: :short, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.non_location_format(unquote(zone), type: :standard, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.non_location_format(unquote(zone), type: :daylight, locale: unquote(locale))
    end

    test "Location format for #{inspect zone} in locale #{inspect locale}" do
      assert {:ok, _} =
        Cldr.DateTime.Timezone.location_format(unquote(zone), format: :long, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.location_format(unquote(zone), format: :short, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.location_format(unquote(zone), type: :standard, locale: unquote(locale))
      assert {:ok, _} =
        Cldr.DateTime.Timezone.location_format(unquote(zone), type: :daylight, locale: unquote(locale))
    end
  end
end
