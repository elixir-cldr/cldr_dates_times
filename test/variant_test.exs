defmodule Cldr.DateTime.VariantTest do
  use ExUnit.Case, async: true

  test "Time Unicode or ASCII preference" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    unicode = Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :unicode, locale: :en)
    ascii = Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :ascii, locale: :en)
    assert unicode != ascii
  end

  test "Time preference" do
    datetime = ~U[2024-07-07 21:36:00.440105Z]

    assert {:ok, "Sun 9:36 PM"} =
             Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :unicode, locale: :en)

    assert {:ok, "Sun 9:36 PM"} =
             Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: :ascii, locale: :en)

    assert {:ok, "Sun 9:36 PM"} =
             Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: [:unicode], locale: :en)

    assert {:ok, "Sun 9:36 PM"} =
             Cldr.DateTime.to_string(datetime, format: :Ehm, prefer: [:ascii], locale: :en)
  end

  test "Date interval variant" do
    assert {:ok, "1/1/2024 – 1/2/2024"} =
             Cldr.Date.Interval.to_string(~D[2024-01-01], ~D[2024-02-01],
               format: :yMd,
               prefer: :variant,
               locale: "en-CA"
             )

    assert {:ok, "1/1/2024–2/1/2024"} =
             Cldr.Date.Interval.to_string(~D[2024-01-01], ~D[2024-02-01],
               format: :yMd,
               prefer: :default,
               locale: "en-CA"
             )

    assert {:ok, "1/1/2024 – 1/2/2024"} =
             Cldr.Date.Interval.to_string(~D[2024-01-01], ~D[2024-02-01],
               format: :yMd,
               prefer: [:variant],
               locale: "en-CA"
             )

    assert {:ok, "1/1/2024–2/1/2024"} =
             Cldr.Date.Interval.to_string(~D[2024-01-01], ~D[2024-02-01],
               format: :yMd,
               prefer: [:default],
               locale: "en-CA"
             )

    assert {:ok, "1/1/2024–2/1/2024"} =
             Cldr.Date.Interval.to_string(~D[2024-01-01], ~D[2024-02-01],
               format: :yMd,
               locale: "en-CA"
             )
  end

  test "Date variant" do
    assert {:ok, "1/3/2024"} =
             Cldr.Date.to_string(~D[2024-03-01], format: :yMd, prefer: :variant, locale: "en-CA")

    assert {:ok, "2024-03-01"} =
             Cldr.Date.to_string(~D[2024-03-01], format: :yMMdd, prefer: :default, locale: "en-CA")

    assert {:ok, "1/3/2024"} =
             Cldr.Date.to_string(~D[2024-03-01], format: :yMd, prefer: [:variant], locale: "en-CA")

    assert {:ok, "2024-03-01"} =
             Cldr.Date.to_string(~D[2024-03-01],
               format: :yMMdd,
               prefer: [:default],
               locale: "en-CA"
             )

    assert {:ok, "2024-03-01"} =
             Cldr.Date.to_string(~D[2024-03-01], format: :yMMdd, locale: "en-CA")
  end
end
