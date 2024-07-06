defmodule Cldr.Exceptions.Test do
  use ExUnit.Case, async: true

  test "that an invalid datetime raises" do
    assert_raise ArgumentError,
                 ~r/Invalid DateTime. DateTime is a map that contains at least .*/,
                 fn ->
                   Cldr.DateTime.to_string!("not a date")
                 end
  end

  test "that an invalid date raises" do
    assert_raise ArgumentError, ~r/Missing required date fields. .*/, fn ->
      Cldr.Date.to_string!("not a date")
    end
  end

  test "that an invalid time raises" do
    assert_raise ArgumentError, ~r/Invalid time. Time is a map that contains at least .*/, fn ->
      Cldr.Time.to_string!("not a time")
    end
  end

  if Version.compare(System.version(), "1.10.0-dev") in [:gt, :eq] do
    test "that an unfulfilled format directive returns an error" do
      assert Cldr.Date.to_string(~D[2019-01-01], format: "x") ==
               {:error,
                {Cldr.DateTime.FormatError,
                 "The format symbol 'x' requires at map with at least :utc_offset. Found: ~D[2019-01-01 Cldr.Calendar.Gregorian]"}}
    end
  end
end
