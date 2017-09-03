defmodule Cldr.DateTime.Compiler do
  @moduledoc """
  Tokenizes and parses `Date`, `Time` and `DateTime` format strings.

  During compilation, each of the date, time and datetime format
  strings defined in CLDR are compiled into a list of
  function bodies that are then grafted onto the function head
  `Cldr.DateTime.Formatter.format/3`.  As a result these compiled
  formats execute with good performance.

  For formats not defined in CLDR (ie a user defined format),
  the tokenizing and parsing is performed, then list of function
  bodies is created and then `Cldr.DateTime.Formatter.format/3`
  recurses over the list, invoking each function and
  collecting the results.  This process is significantly slower
  than that of the precompiled formats.

  User defined formats can also be precompiled by configuring
  them under the key `:precompile_datetime_formats`.  For example:

      config :ex_cldr,
        precompile_datetime_formats: ["yy/dd", "hhh:mmm:sss"]

  """

  alias Cldr.DateTime.Formatter

  @doc """
  Scan a number format definition and return
  the tokens of a date/time/datetime format
  string.

  This function is designed to produce output
  that is fed into `Cldr.DateTime.Compiler.compile/1`.

  ## Example

      iex> Cldr.DateTime.Compiler.tokenize "yyyy/MM/dd"
      {:ok,
       [{:year, 1, 4}, {:literal, 1, "/"}, {:month, 1, 2}, {:literal, 1, "/"},
        {:day_of_month, 1, 2}], 1}
  """
  def tokenize(definition) when is_binary(definition) do
    definition
    |> String.to_charlist
    |> :datetime_format_lexer.string()
  end

  def tokenize(%{number_system: _numbers, format: value}) do
    tokenize(value)
  end

  @doc """
  Parse a number format definition

  * `format_string` is a string defining how a date/time/datetime
  is to be formatted.  See `Cldr.DateTime.Formatter` for the list
  of supported format symbols.

  Returns is a list of function bodies which are grafted onto
  a function head in `Cldr.DateTime.Formatter` at compile time
  to produce a series of functions that process a given format
  string efficiently.
  """
  @spec compile(String.t) :: {:ok, List.t} | {:error, String.t}
  def compile(format_string)

  def compile("") do
    {:error, "empty format string cannot be compiled"}
  end

  def compile(nil) do
    {:error, "no format string or token list provided"}
  end

  def compile(definition) when is_binary(definition) do
    {:ok, tokens, _end_line} = tokenize(definition)

    transforms = Enum.map(tokens, fn {fun, _line, count} ->
      quote do
        Formatter.unquote(fun)(var!(date), unquote(count), var!(locale), var!(options))
      end
    end)

    {:ok, transforms}
  end

  def compile(%{number_system: _number_system, format: value}) do
    compile(value)
  end

  def compile(arg) do
    raise ArgumentError, message: "No idea how to compile format: #{inspect arg}"
  end
end
