defmodule Cldr.DateTime.WrapperTest do
  use ExUnit.Case

  test "wrapping a datetime" do
    wrapper = fn value, type ->
      ["<", to_string(type), ">", to_string(value), "</", to_string(type), ">"]
    end

    assert {:ok,
        "<month>Mar</month><literal> </literal><day>13</day>" <>
        "<literal>, </literal><year>2023</year><literal>, </literal>" <>
        "<h12>9</h12><literal>:</literal><minute>41</minute>" <>
        "<literal>:</literal><second>00</second><literal> </literal>" <>
        "<period_am_pm>PM</period_am_pm>"
      } = Cldr.DateTime.to_string(~U[2023-03-13T21:41:00.0Z], wrapper: wrapper)
  end

end