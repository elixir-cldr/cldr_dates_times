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
    assert match?({:ok, _now}, MyApp.Cldr.DateTime.to_string(DateTime.utc_now()))
    assert match?({:ok, _now}, MyApp.Cldr.Date.to_string(Date.utc_today()))
    assert match?({:ok, _now}, MyApp.Cldr.Time.to_string(DateTime.utc_now()))
    Application.put_env(:ex_cldr, :default_backend, default_backend)
  end

  test "to_string/2 when the second param is options (not backend)" do
    assert Cldr.Date.to_string(~D[2022-01-22], backend: MyApp.Cldr) == {:ok, "Jan 22, 2022"}
    assert Cldr.DateTime.to_string(~U[2022-01-22T01:00:00.0Z], backend: MyApp.Cldr) == {:ok, "Jan 22, 2022, 1:00:00 AM"}
    assert Cldr.Time.to_string(~T[01:23:00], backend: MyApp.Cldr) == {:ok, "1:23:00 AM"}

    assert Cldr.Date.to_string!(~D[2022-01-22], backend: MyApp.Cldr) == "Jan 22, 2022"
    assert Cldr.DateTime.to_string!(~U[2022-01-22T01:00:00.0Z], backend: MyApp.Cldr) == "Jan 22, 2022, 1:00:00 AM"
    assert Cldr.Time.to_string!(~T[01:23:00], backend: MyApp.Cldr) == "1:23:00 AM"
  end

  test "DateTime at formats" do
    date_time = ~U[2023-09-08 15:50:00Z]

    assert Cldr.DateTime.to_string(date_time, format: :full, style: :at) ==
      {:ok, "Friday, September 8, 2023 at 3:50:00 PM GMT"}

    assert Cldr.DateTime.to_string(date_time, format: :long, style: :at) ==
      {:ok, "September 8, 2023 at 3:50:00 PM UTC"}

    assert Cldr.DateTime.to_string(date_time, format: :full, style: :at, locale: :fr) ==
      {:ok, "vendredi 8 septembre 2023 à 15:50:00 UTC"}

    assert Cldr.DateTime.to_string(date_time, format: :long, style: :at, locale: :fr) ==
      {:ok, "8 septembre 2023 à 15:50:00 UTC"}
  end
end
