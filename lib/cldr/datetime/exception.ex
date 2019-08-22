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

defmodule Cldr.DateTime.Compiler.ParseError do
  @moduledoc """
  Exception raised when tokenizing a datetime format.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
