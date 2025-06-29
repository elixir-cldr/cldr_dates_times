defmodule Cldr.DateTime.DurationFormatTest do
  use ExUnit.Case, async: true

  test "Formatting a Cldr.Calendar.Duration" do
    duration = Cldr.Calendar.Duration.new_from_seconds(136_092)
    assert {:ok, "37:48:12"} = Cldr.Time.to_string(duration, format: "hh:mm:ss")
  end

  if Code.ensure_loaded?(Duration) do
    test "Formatting a Duration" do
      duration = Duration.new!(hour: 28, minute: 15, second: 6)
      assert {:ok, "28:15:06"} = Cldr.Time.to_string(duration, format: "hh:mm:ss")
    end
  end
end
