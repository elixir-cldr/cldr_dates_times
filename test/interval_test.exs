defmodule Cldr.DateTime.Interval.Test do
  use ExUnit.Case, async: true

  test "date formatting" do
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01])
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01], MyApp.Cldr)
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01], locale: "fr")
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01], MyApp.Cldr, locale: "fr")
  end

  test "right open date interval" do
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], nil) == {:ok, "Jan 1, 2020 –"}
    assert Cldr.Date.Interval.to_string(~D[2020-01-01], nil, MyApp.Cldr) == {:ok, "Jan 1, 2020 –"}

    assert Cldr.Date.Interval.to_string(~D[2020-01-01], nil, locale: "fr") ==
             {:ok, "1 janv. 2020 –"}

    assert Cldr.Date.Interval.to_string(~D[2020-01-01], nil, MyApp.Cldr, locale: "fr") ==
             {:ok, "1 janv. 2020 –"}
  end

  test "left open date interval" do
    assert Cldr.Date.Interval.to_string(nil, ~D[2020-01-01]) == {:ok, "– Jan 1, 2020"}
    assert Cldr.Date.Interval.to_string(nil, ~D[2020-01-01], MyApp.Cldr) == {:ok, "– Jan 1, 2020"}

    assert Cldr.Date.Interval.to_string(nil, ~D[2020-01-01], locale: "fr") ==
             {:ok, "– 1 janv. 2020"}

    assert Cldr.Date.Interval.to_string(nil, ~D[2020-01-01], MyApp.Cldr, locale: "fr") ==
             {:ok, "– 1 janv. 2020"}
  end

  test "time formatting" do
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0])
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0], MyApp.Cldr)
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0], locale: "fr")
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0], MyApp.Cldr, locale: "fr")

    assert Cldr.Time.Interval.to_string(~T[10:00:00], ~T[22:03:00], MyApp.Cldr,
             format: :short,
             locale: "en-GB"
           ) == {:ok, "10 – 22"}
  end

  test "right option time interval" do
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], nil) == {:ok, "12:00:00 AM –"}
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], nil, MyApp.Cldr) == {:ok, "12:00:00 AM –"}
    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], nil, locale: "fr") == {:ok, "00:00:00 –"}

    assert Cldr.Time.Interval.to_string(~T[00:00:00.0], nil, MyApp.Cldr, locale: "fr") ==
             {:ok, "00:00:00 –"}
  end

  test "left option time interval" do
    assert Cldr.Time.Interval.to_string(nil, ~T[00:00:00.0]) == {:ok, "– 12:00:00 AM"}
    assert Cldr.Time.Interval.to_string(nil, ~T[00:00:00.0], MyApp.Cldr) == {:ok, "– 12:00:00 AM"}
    assert Cldr.Time.Interval.to_string(nil, ~T[00:00:00.0], locale: "fr") == {:ok, "– 00:00:00"}

    assert Cldr.Time.Interval.to_string(nil, ~T[00:00:00.0], MyApp.Cldr, locale: "fr") ==
             {:ok, "– 00:00:00"}
  end

  # Just to get tests compiling. Those tests will
  # then be omitted by the tag
  unless Version.match?(System.version(), "~> 1.9") do
    defmacrop sigil_U(string, _options) do
      string
    end
  end

  @tag :elixir_1_9
  test "datetime formatting" do
    assert Cldr.DateTime.Interval.to_string(~U[2020-01-01 00:00:00.0Z], ~U[2020-02-01 10:00:00.0Z])

    assert Cldr.DateTime.Interval.to_string(
             ~U[2020-01-01 00:00:00.0Z],
             ~U[2020-02-01 10:00:00.0Z],
             MyApp.Cldr
           )

    assert Cldr.DateTime.Interval.to_string(~U[2020-01-01 00:00:00.0Z], ~U[2020-02-01 10:00:00.0Z],
             locale: "fr"
           )

    assert Cldr.DateTime.Interval.to_string(
             ~U[2020-01-01 00:00:00.0Z],
             ~U[2020-02-01 10:00:00.0Z],
             MyApp.Cldr,
             locale: "fr"
           )

    assert Cldr.DateTime.Interval.to_string(
             ~U[2020-01-01 00:00:00.0Z],
             nil,
             MyApp.Cldr,
             locale: "fr"
           ) == {:ok, "1 janv. 2020, 00:00:00 –"}

    assert Cldr.DateTime.Interval.to_string(
             nil,
             ~U[2020-01-01 00:00:00.0Z],
             MyApp.Cldr,
             locale: "fr"
           ) == {:ok, "– 1 janv. 2020, 00:00:00"}
  end

  test "backend date formatting" do
    assert MyApp.Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01])
    assert MyApp.Cldr.Date.Interval.to_string(~D[2020-01-01], ~D[2020-02-01], locale: "fr")
  end

  test "backend time formatting" do
    assert MyApp.Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0])
    assert MyApp.Cldr.Time.Interval.to_string(~T[00:00:00.0], ~T[10:00:00.0], locale: "fr")
  end

  @tag :elixir_1_9
  test "backend datetime formatting" do
    assert MyApp.Cldr.DateTime.Interval.to_string(
             ~U[2020-01-01 00:00:00.0Z],
             ~U[2020-02-01 10:00:00.0Z]
           )

    assert MyApp.Cldr.DateTime.Interval.to_string(
             ~U[2020-01-01 00:00:00.0Z],
             ~U[2020-02-01 10:00:00.0Z],
             locale: "fr"
           )
  end

  test "Error returns" do
    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             number_system: "unknown"
           ) ==
             {:error, {Cldr.UnknownNumberSystemError, "The number system \"unknown\" is invalid"}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             locale: "unknown"
           ) ==
             {:error, {Cldr.InvalidLanguageError, "The language \"unknown\" is invalid"}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             format: "unknown"
           ) ==
             {:error,
              {Cldr.DateTime.Compiler.ParseError,
               "Could not tokenize \"unk\". Error detected at " <> inspect([?n])}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             format: :unknown
           ) ==
             {:error,
              {Cldr.DateTime.UnresolvedFormat,
               "The interval format :unknown is invalid. Valid formats are [:long, :medium, :short] or an interval format string."}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             style: :unknown
           ) ==
             {:error,
              {Cldr.DateTime.InvalidStyle,
               "The interval style :unknown is invalid. Valid styles are [:date, :month, :month_and_day, :year_and_month]."}}

    assert Cldr.Date.Interval.to_string(Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
             style: "unknown"
           ) ==
             {:error,
              {Cldr.DateTime.InvalidStyle,
               "The interval style \"unknown\" is invalid. Valid styles are [:date, :month, :month_and_day, :year_and_month]."}}
  end

  test "time intervals that cross midday" do
    assert Cldr.Time.Interval.to_string!(~T[08:00:00], ~T[22:00:00]) == "8:00 AM – 10:00 PM"
    assert Cldr.Time.Interval.to_string!(~T[20:00:00], ~T[22:00:00]) == "8:00 – 10:00 PM"
  end

  test "time intervals obey locale's hour format" do
    assert {:ok, "12:00 – 13:00"} =
             Cldr.Time.Interval.to_string(~T[12:00:00], ~T[13:00:00], MyApp.Cldr, locale: :fr)

    assert {:ok, "12:00 – 1:00 PM"} =
             Cldr.Time.Interval.to_string(~T[12:00:00], ~T[13:00:00], MyApp.Cldr, locale: :en)
  end

  test "Interval formatting when the format is a string" do
    assert {:ok, "12:00:00 - 13:00:00"} =
             MyApp.Cldr.Time.Interval.to_string(~T[12:00:00], ~T[13:00:00],
               format: "HH:mm:ss - HH:mm:ss",
               locale: :fr
             )
  end

  test "Interval formatting of dates with :month_and_day where the last date is in a subsequent year" do
    assert {:ok, "12/31 – 1/2"} =
             MyApp.Cldr.Date.Interval.to_string(~D[2023-12-31], ~D[2024-01-02],
               format: :short,
               style: :month_and_day
             )
  end

  test "Interval formats with different date and time formats" do
    assert {:ok, "January 1, 2020, 12:00 AM – December 31, 2020, 10:00 AM"} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-12-31 10:00:00.0Z],
               format: :medium,
               date_format: :long,
               time_format: :short
             )

    assert {:ok, "January 1, 2020, 12:00 AM – 10:00 AM"} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: :medium,
               date_format: :long,
               time_format: :short
             )

    assert {:ok, "1/1/20, 12:00 AM – 12/31/20, 10:00 AM"} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-12-31 10:00:00.0Z],
               format: :medium,
               date_format: :short,
               time_format: :short
             )

    assert {:ok, "1/1/20, 12:00 AM – 10:00 AM"} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: :medium,
               date_format: :short,
               time_format: :short
             )
  end

  test "Invalid :date_format and :time_format for intervals" do
    assert {:error,
            {Cldr.DateTime.InvalidFormat,
             ":date_format and :time_format must be one of [:short, :medium, :long] if :format is also one of [:short, :medium, :long]. Found :short and \"invalid\"."}} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: :medium,
               date_format: :short,
               time_format: "invalid"
             )

    assert {:error,
            {Cldr.DateTime.InvalidFormat,
             ":date_format and :time_format must be one of [:short, :medium, :long] if :format is also one of [:short, :medium, :long]. Found \"invalid\" and :short."}} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: :medium,
               date_format: "invalid",
               time_format: :short
             )
  end

  test "If :format is a string or atom (other than standard formats) then :date_format and :time_format are not permitted" do
    assert {:error,
            {Cldr.DateTime.InvalidFormat,
             ":date_format and :time_format cannot be specified when the interval format is a binary or atom other than one of [:short, :medium, :long]. Found: \"y-M-d - d\"."}} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: "y-M-d - d",
               date_format: :short,
               time_format: :long
             )

    assert {:error,
            {Cldr.DateTime.InvalidFormat,
             ":date_format and :time_format cannot be specified when the interval format is a binary or atom other than one of [:short, :medium, :long]. Found: :gMY."}} =
             MyApp.Cldr.DateTime.Interval.to_string(
               ~U[2020-01-01 00:00:00.0Z],
               ~U[2020-01-01 10:00:00.0Z],
               format: :gMY,
               date_format: :short,
               time_format: :short
             )
  end
end
