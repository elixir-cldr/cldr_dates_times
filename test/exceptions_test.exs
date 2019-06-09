defmodule Cldr.Exceptions.Test do
  use ExUnit.Case, async: true

  test "that an invalid datetime raises" do
    assert_raise ArgumentError,
                 ~r/Invalid date_time. Date_time is a map that requires at least .*/,
                 fn ->
                   Cldr.DateTime.to_string!("not a date")
                 end
  end

  test "that an invalid date raises" do
    assert_raise ArgumentError, ~r/Invalid date. Date is a map that requires at least .*/, fn ->
      Cldr.Date.to_string!("not a date")
    end
  end

  test "that an invalid time raises" do
    assert_raise ArgumentError, ~r/Invalid time. Time is a map that requires at least .*/, fn ->
      Cldr.Time.to_string!("not a time")
    end
  end
end
