defmodule Cldr.DateTime.TestHelpers do
  def non_location_zones(zone) do
    !String.starts_with?(zone, "Etc") && !String.starts_with?(zone, "GMT") && zone != "Greenwich"
  end
end