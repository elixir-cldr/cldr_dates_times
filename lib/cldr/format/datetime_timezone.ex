defmodule Cldr.DateTime.Timezone do
  @doc """
  Converts the time zone offset of a `Time` or `DateTime` into
  seconds.
  """
  def time_from_zone_offset(%{utc_offset: utc_offset, std_offset: std_offset}) do
    offset = utc_offset + std_offset

    hours = div(offset, 3600)
    minutes = div(offset - hours * 3600, 60)
    seconds = offset - hours * 3600 - minutes * 60
    {hours, minutes, seconds}
  end

  def time_from_zone_offset(other) do
    Cldr.DateTime.Formatter.error_return(other, "x", [:utc_offset])
  end
end
