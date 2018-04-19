defmodule Cldr.UnknownTimeUnit do
  @moduledoc """
  Exception raised when an attempt is made to use a time unit that is not known.
  in `Cldr.DateTime.Relative`.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
