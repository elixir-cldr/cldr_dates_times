defmodule Cldr.DateTime.TimezoneTest do
  use ExUnit.Case, async: true

  test "Exemplar City when timezone data exists but has no exemplar field" do
    assert {:ok, "Honolulu"} = Cldr.DateTime.Timezone.exemplar_city("Pacific/Honolulu")
  end

end