defmodule Cldr.DatesTimes.Test do
  use ExUnit.Case, async: true

  test "that the bb format works as expected" do
    assert Cldr.DateTime.to_string(
             %{
               year: 2018,
               month: 1,
               day: 1,
               hour: 0,
               minute: 0,
               second: 0,
               calendar: Calendar.ISO
             },
             MyApp.Cldr,
             format: "YYYY-MMM-dd KK:mm bb"
           ) == {:ok, "2018-Jan-01 00:00 midnight"}

    assert Cldr.DateTime.to_string(
             %{
               year: 2018,
               month: 1,
               day: 1,
               hour: 0,
               minute: 1,
               second: 0,
               calendar: Calendar.ISO
             },
             MyApp.Cldr,
             format: "YYYY-MMM-dd KK:mm bb"
           ) == {:ok, "2018-Jan-01 00:01 AM"}
  end

  test "That localised date doesn't transliterate" do
    assert Cldr.Date.to_string(~D[2019-06-12], MyApp.Cldr, locale: "de") == {:ok, "12.06.2019"}
  end
end
