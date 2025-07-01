defmodule Cldr.DateTime.TestHelpers do
  @avoid_zones ["Greenwich", "Factory"]
  def non_location_zones(zone) do
    !String.starts_with?(zone, "Etc") && !String.starts_with?(zone, "GMT") &&
      zone not in @avoid_zones
  end
end
