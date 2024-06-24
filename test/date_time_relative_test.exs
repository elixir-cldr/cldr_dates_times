defmodule Cldr.DateTime.Relative.Test do
  use ExUnit.Case, async: true

  @date ~D[2021-10-01]
  @relative_to ~D[2021-09-19]

  @datetime ~U[2021-10-01 10:15:00+00:00]
  @relative_datetime_to ~U[2021-09-19 12:15:00+00:00]

  alias MyApp.Cldr.DateTime.Relative

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
end
