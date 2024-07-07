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

    assert Cldr.DateTime.to_string(~U[2022-01-22T01:00:00.0Z], backend: MyApp.Cldr) ==
             {:ok, "Jan 22, 2022, 1:00:00 AM"}

    assert Cldr.Time.to_string(~T[01:23:00], backend: MyApp.Cldr) == {:ok, "1:23:00 AM"}

    assert Cldr.Date.to_string!(~D[2022-01-22], backend: MyApp.Cldr) == "Jan 22, 2022"

    assert Cldr.DateTime.to_string!(~U[2022-01-22T01:00:00.0Z], backend: MyApp.Cldr) ==
             "Jan 22, 2022, 1:00:00 AM"

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

  test "Era variants" do
    assert {:ok, "2024/7/6 CE"} =
             Cldr.Date.to_string(~D[2024-07-06], era: :variant, format: "y/M/d G")

    assert {:ok, "2024/7/6 AD"} = Cldr.Date.to_string(~D[2024-07-06], format: "y/M/d G")
  end

  test "Resolving with skeleton code c, J and j" do
    assert {:ok, "10:48 AM"} = Cldr.Time.to_string(~T[10:48:00], format: :hmj)
    assert {:ok, "10:48 AM"} = Cldr.Time.to_string(~T[10:48:00], format: :hmJ)

    assert Cldr.Date.to_string(~T[10:48:00], format: :hmc) ==
             {:error, {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :hmc"}}

    assert Cldr.Time.to_string(~T[10:48:00], format: :hme) ==
             {:error, {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :hme"}}
  end

  test "Datetime formatting with standard formats" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    assert {:ok, "Jul 7, 2024, 9:36:00 PM"} =
             Cldr.DateTime.to_string(datetime)

    assert {:ok, "7/7/24, 9:36:00 PM GMT"} =
             Cldr.DateTime.to_string(datetime, date_format: :short, time_format: :full)

    assert {:ok, "7/7/24, 9:36:00 PM GMT"} =
             Cldr.DateTime.to_string(datetime,
               format: :medium,
               date_format: :short,
               time_format: :full
             )
  end

  test "Datetime format option consistency" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    assert Cldr.DateTime.to_string(datetime,
             format: "yyy",
             date_format: :short,
             time_format: :medium
           ) ==
             {:error,
              {Cldr.DateTime.InvalidFormat,
               ":date_format and :time_format cannot be specified if :format is also specified as a " <>
                 "format id or a format string. Found [time_format: :medium, date_format: :short]"}}

    assert Cldr.DateTime.to_string(datetime,
             format: :yMd,
             date_format: :short,
             time_format: :medium
           ) ==
             {:error,
              {Cldr.DateTime.InvalidFormat,
               ":date_format and :time_format cannot be specified if :format is also specified as a " <>
                 "format id or a format string. Found [time_format: :medium, date_format: :short]"}}
  end

  test "Pluralized formats" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    assert {:ok, "week 28 of 2024"} = Cldr.DateTime.to_string(~D[2024-07-08], format: :yw)
    assert {:ok, "week 2 of July"} = Cldr.DateTime.to_string(~D[2024-07-08], format: :MMMMW)
    assert {:ok, "8:11 AM"} = Cldr.DateTime.to_string(~T[08:11:02], format: :hm)
    assert {:ok, "Sun 9:36 PM"} = Cldr.DateTime.to_string(datetime, format: :Ehm)
  end

  test "Unicode or ASCII preference" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    unicode = Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :unicode)
    ascii = Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :ascii)
    assert unicode != ascii
  end

  test "'at' formats" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    assert {:ok, "July 7, 2024 at 9:36:00 PM UTC"} =
      Cldr.DateTime.to_string(datetime, format: :long, style: :at)

    assert {:ok, "July 7, 2024, 9:36:00 PM UTC"} =
      Cldr.DateTime.to_string(datetime, format: :long, style: :default)
  end
end
