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

defmodule Cldr.DateTime.UnresolvedFormat do
  @moduledoc """
  Exception raised when formatting and there is no
  data for the given format.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.DateTime.InvalidStyle do
  @moduledoc """
  Exception raised when formatting and there is no
  data for the given style.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.DateTime.IntervalFormatError do
  @moduledoc """
  Exception raised when attempting to
  compile an interval format.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.DateTime.DateTimeOrderError do
  @moduledoc """
  Exception raised when the first
  datetime in an interval is greater than
  the last datetime.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.DateTime.IncompatibleTimeZonerError do
  @moduledoc """
  Exception raised when the two
  datetimes are in different time zones
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
