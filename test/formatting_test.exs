defmodule Cldr.DateTime.Formatting.Test do
  use ExUnit.Case, async: true

  test "Hour cycle override in locale" do
    assert "23:00:00" = Cldr.Time.to_string!(~T[23:00:00], locale: "en-u-hc-h23")
    assert "00:01:00" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-h23")
    assert "12:01:00 AM" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-h12")
    assert "11:00:00 PM" = Cldr.Time.to_string!(~T[23:00:00], locale: "en")
  end

  test "Hour cycle override with locale preference" do
    assert "12:01:00 AM" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-c12")
    assert "00:01:00" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-c24")

    assert "12:01:00 nachts" = Cldr.Time.to_string!(~T[00:01:00], locale: "de-u-hc-c12")
    assert "00:01:00" = Cldr.Time.to_string!(~T[00:01:00], locale: "de-u-hc-c24")
  end

  test "Best match for c12 and c24" do
    assert {:ok, {:Md, :Bhms}} =
             Cldr.DateTime.Format.Match.best_match(:Mdjms, "de-u-hc-c12", :gregorian)

    assert {:ok, {:Md, :Hms}} =
             Cldr.DateTime.Format.Match.best_match(:Mdjms, "de-u-hc-c24", :gregorian)

    assert {:ok, {:Md, :Hms}} =
             Cldr.DateTime.Format.Match.best_match(:Mdjms, "en-u-hc-c24", :gregorian)

    assert {:ok, {:Md, :hms}} =
             Cldr.DateTime.Format.Match.best_match(:Mdjms, "en-u-hc-c12", :gregorian)
  end

  test "DateTime formatting with specified date and time formats" do
    assert {:ok, "10/15/2025, 13:55:00"} =
             Cldr.DateTime.to_string(~U[2025-10-15T13:55:00Z],
               format: :long,
               date_format: :yMd,
               time_format: :Hms
             )

    assert {:ok, "10/15/2025, 1:55:00 PM"} =
             Cldr.DateTime.to_string(~U[2025-10-15T13:55:00Z],
               format: :long,
               date_format: :yMd,
               time_format: :hms
             )

    assert {:ok, "Oct 15, 2025, 1:55:00 PM"} =
             Cldr.DateTime.to_string(~U[2025-10-15T13:55:00Z],
               format: :long,
               date_format: :yMMMd,
               time_format: :hms
             )

    assert Cldr.DateTime.to_string(~U[2025-10-15T13:55:00Z],
             format: :long,
             date_format: :yMMMd,
             time_format: :dhms
           ) ==
             {:error, {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :dhms"}}
  end

  test "That tz format codes are removed from the skeleton before best match if the time is naive" do
    assert {:ok, "October 15, 2025, 1:55:00 PM"} =
             Cldr.DateTime.to_string(~N[2025-10-15T13:55:00], format: :long, time_format: :full)

    assert {:ok, "October 15, 2025, 1:55:00 PM Coordinated Universal Time"} =
             Cldr.DateTime.to_string(~U[2025-10-15T13:55:00Z], format: :long, time_format: :full)
  end
end
