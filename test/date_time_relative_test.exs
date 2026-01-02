defmodule Cldr.DateTime.Relative.Test do
  use ExUnit.Case, async: true

  @date ~D[2021-10-01]
  @relative_to ~D[2021-09-19]

  @datetime ~U[2021-10-01 10:15:00+00:00]
  @relative_datetime_to ~U[2021-09-19 12:15:00+00:00]

  @time ~T[18:11:01]
  @relative_time_to ~T[11:52:03]

  alias MyApp.Cldr.DateTime.Relative

  test "Relative times with specified unit" do
    assert Relative.to_string(@time, relative_to: @relative_time_to, unit: :hour) ==
             {:ok, "in 6 hours"}

    assert Relative.to_string(@time, relative_to: @relative_time_to, unit: :minute) ==
             {:ok, "in 379 minutes"}

    assert Relative.to_string(@time, relative_to: @relative_time_to, unit: :second) ==
             {:ok, "in 22,738 seconds"}
  end

  test "Relative dates with specified unit" do
    assert Relative.to_string(@date, relative_to: @relative_to) ==
             {:ok, "in 2 weeks"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :day) ==
             {:ok, "in 12 days"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :month) ==
             {:ok, "this month"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :week) ==
             {:ok, "in 2 weeks"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :hour) ==
             {:ok, "in 288 hours"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :minute) ==
             {:ok, "in 17,280 minutes"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :second) ==
             {:ok, "in 1,036,800 seconds"}

    assert Relative.to_string(@date, relative_to: @relative_to, unit: :year) ==
             {:ok, "this year"}
  end

  test "Relative datetime with specified unit" do
    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to) ==
             {:ok, "in 2 weeks"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :day) ==
             {:ok, "in 12 days"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :month) ==
             {:ok, "this month"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :week) ==
             {:ok, "in 2 weeks"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :hour) ==
             {:ok, "in 286 hours"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :minute) ==
             {:ok, "in 17,160 minutes"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :second) ==
             {:ok, "in 1,029,600 seconds"}

    assert Relative.to_string(@datetime, relative_to: @relative_datetime_to, unit: :year) ==
             {:ok, "this year"}
  end

  test "Relative date with derive unit function" do
    assert {:ok, "in 3 months"} =
             Relative.to_string(~D[2017-04-29],
               relative_to: ~D[2017-01-26],
               derive_unit_from: &Cldr.DateTime.Relative.derive_unit_from/4
             )
  end

  test "Relative time" do
    assert {:ok, "in 6 hours"} =
             Relative.to_string(@time,
               relative_to: @relative_time_to,
               derive_unit_from: &Cldr.DateTime.Relative.derive_unit_from/4
             )

    assert {:ok, "in 6 hours"} =
             Relative.to_string(@time, relative_to: @relative_time_to)
  end

  test "Relative at time" do
    assert {:ok, "tomorrow at 6:11 PM"} =
             Cldr.DateTime.Relative.to_string(1,
               style: :at,
               time: @time,
               unit: :day,
               at_format: :long
             )

    assert {:ok, "demain à 18:11"} =
             Cldr.DateTime.Relative.to_string(1,
               style: :at,
               time: @time,
               unit: :day,
               at_format: :long,
               locale: :fr
             )
  end
end
