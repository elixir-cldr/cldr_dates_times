defmodule Cldr.DateTime.Formatting.Test do
  use ExUnit.Case, async: true

  test "Hour cycle override in locale" do
    assert "23:00:00" = Cldr.Time.to_string!(~T[23:00:00], locale: "en-u-hc-h23")
    assert "00:01:00" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-h23")
    assert "12:01:00 AM" = Cldr.Time.to_string!(~T[00:01:00], locale: "en-u-hc-h12")
    assert "11:00:00 PM" = Cldr.Time.to_string!(~T[23:00:00], locale: "en")
  end

end