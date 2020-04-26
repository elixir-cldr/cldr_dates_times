defmodule Cldr.DateTime.CharsTest do
  use ExUnit.Case, async: true

  test "date to_string" do
    assert Cldr.to_string(~D[2020-04-09]) == "Apr 9, 2020"
  end

  test "time to_string" do
    assert Cldr.to_string(~T[11:45:23]) == "11:45:23 AM"
  end

  test "naive datetime to_string" do
    assert Cldr.to_string(~N[2020-04-09 23:39:25]) == "Apr 9, 2020, 11:39:25 PM"
  end

  if Version.match?(System.version(), "~> 1.9") do
    test "datetime to_string" do
      assert Cldr.to_string(~U[2020-04-09 23:39:25.040129Z]) == "Apr 9, 2020, 11:39:25 PM"
    end
  end
end
