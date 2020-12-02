defmodule Cldr.DatesTimes.Test do
  use ExUnit.Case

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

  test "Formatting via a backend when there is no default backend" do
    default_backend = Application.get_env(:ex_cldr, :default_backend)
    Application.put_env(:ex_cldr, :default_backend, nil)
    assert match?({:ok, _now}, MyApp.Cldr.DateTime.to_string(DateTime.utc_now))
    assert match?({:ok, _now}, MyApp.Cldr.Date.to_string(Date.utc_today))
    assert match?({:ok, _now}, MyApp.Cldr.Time.to_string(DateTime.utc_now))
    Application.put_env(:ex_cldr, :default_backend, default_backend)
  end

end
