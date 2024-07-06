defmodule Cldr.DateTime.PartialTest do
  use ExUnit.Case, async: true

  test "Partial Dates" do
    assert {:ok, "2024"} = Cldr.Date.to_string(%{year: 2024})
    assert {:ok, "3/2024"} = Cldr.Date.to_string(%{year: 2024, month: 3})
    assert {:ok, "3/5"} = Cldr.Date.to_string(%{month: 3, day: 5})
    assert {:ok, "5-3"} = Cldr.Date.to_string(%{month: 3, day: 5}, format: "d-M")

    assert Cldr.Date.to_string(%{year: 3, day: 5}, format: "d-M") ==
      {:error,
       {Cldr.DateTime.FormatError,
        "The format symbol 'M' requires at map with at least :month. " <>
        "Found: %{calendar: Cldr.Calendar.Gregorian, day: 5, year: 3}"}}

    assert Cldr.Date.to_string(%{year: 3, day: 5}) ==
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "No available format resolved for \"dy\""}}
  end

  test "Partial Times" do
    assert {:ok, "11 PM"} = Cldr.Time.to_string(%{hour: 23})
    assert {:ok, "11:15 PM"} = Cldr.Time.to_string(%{hour: 23, minute: 15})
    assert {:ok, "11:15:45 PM"} = Cldr.Time.to_string(%{hour: 23, minute: 15, second: 45})
    assert {:ok, "23:45"} = Cldr.Time.to_string(%{minute: 23, second: 45})
    assert {:ok, "5:23 AM Australia/Sydney"} =
      Cldr.Time.to_string(%{hour: 5, minute: 23, time_zone: "Australia/Sydney"})

    assert {:ok, "5:23 unk"} =
      Cldr.Time.to_string(%{hour: 5, minute: 23, zone_abbr: "AEST"}, format: "h:m V")

    assert {:ok, "5:23 AEST"} =
      Cldr.Time.to_string(%{hour: 5, minute: 23, zone_abbr: "AEST"}, format: "h:m VV")

    assert {:ok, "5:23 GMT"} =
      Cldr.Time.to_string(%{hour: 5, minute: 23, zone_abbr: "AEST", utc_offset: 0, std_offset: 0}, format: "h:m VVVV")

    assert Cldr.Time.to_string(%{hour: 5, minute: 23, zone_abbr: "AEST"}, format: "h:m VVVV")
      {:error,
        {Cldr.DateTime.FormatError,
         "The format symbol 'x' requires at map with at least :utc_offset. " <>
         "Found: %{calendar: Cldr.Calendar.Gregorian, minute: 23, hour: 5, zone_abbr: \"AEST\"}"}}

    assert Cldr.Time.to_string(%{hour: 23, second: 45}) ==
      {:error,
        {Cldr.DateTime.UnresolvedFormat, "No available format resolved for \"sh\""}}

    assert Cldr.Time.to_string(%{hour: 23, second: 45}, format: "h:m:s") ==
      {:error,
        {Cldr.DateTime.FormatError,
         "The format symbol 'm' requires at map with at least :minute. " <>
         "Found: %{second: 45, calendar: Cldr.Calendar.Gregorian, hour: 23}"}}
  end

  test "Partial date times" do
    assert {:ok, "11/2024, 10 AM"} = Cldr.DateTime.to_string(%{year: 2024, month: 11, hour: 10})
    assert {:ok, "2024, 10 AM"} = Cldr.DateTime.to_string(%{year: 2024, hour: 10})

    assert Cldr.DateTime.to_string(%{year: 2024, minute: 10}) ==
      {:error,
        {Cldr.DateTime.UnresolvedFormat, "No available format resolved for \"m\""}}

  end

  test "Additional error returns" do
    assert Cldr.DateTime.to_string(%{hour: 2024}) ==
      {:error,
       {Cldr.DateTime.FormatError, "Hour must be in the range of 0..24. Found 2024"}}
    assert Cldr.Time.to_string(%{hour: 2024}) ==
      {:error,
       {Cldr.DateTime.FormatError, "Hour must be in the range of 0..24. Found 2024"}}
  end
end