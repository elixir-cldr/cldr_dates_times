defmodule Cldr.DateTime.UnknownTimeUnit do
  @moduledoc """
  Exception raised when an attempt is made to use a time unit that is not known
  in `Cldr.DateTime.Relative`.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.UnknownTimezone do
  @moduledoc """
  Exception raised when an attempt is made to use a time zone that is not known.
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

defmodule Cldr.DateTime.InvalidFormat do
  @moduledoc """
  Exception raised when formatting and there is no
  data for the given format.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.DateTime.FormatError do
  @moduledoc """
  Exception raised when attempting to
  format a date or time which does not have
  the data available to fulfill the format.
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
