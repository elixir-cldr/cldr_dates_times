defmodule Cldr.DateTime.Compiler do
  @moduledoc """
  Tokenizes and parses `Date`, `Time` and `DateTime` format strings.

  During compilation, each of the date, time and datetime format
  strings defined in CLDR are compiled into a list of
  function bodies that are then grafted onto the function head
  `format/3` in a backend module.  As a result these compiled
  formats execute with good performance.

  For formats not defined in CLDR (ie a user defined format),
  the tokenizing and parsing is performed, then list of function
  bodies is created and then `format/3`
  recurses over the list, invoking each function and
  collecting the results.  This process is significantly slower
  than that of the precompiled formats.

  User defined formats can also be precompiled by configuring
  them under the key `:precompile_datetime_formats`.  For example:

      config :ex_cldr,
        precompile_datetime_formats: ["yy/dd", "hhh:mmm:sss"]

  """

  @doc """
  Scan a number format definition and return
  the tokens of a date/time/datetime format
  string.

  This function is designed to produce output
  that is fed into `Cldr.DateTime.Compiler.compile/3`.

  ## Arguments

  * `definition` is a date, datetime or time format
    string

  ## Returns

  A list of 3-tuples which represent the tokens
  of the format definition

  ## Example

      iex> Cldr.DateTime.Compiler.tokenize "yyyy/MM/dd"
      {:ok,
       [{:year, 1, 4}, {:literal, 1, "/"}, {:month, 1, 2}, {:literal, 1, "/"},
        {:day_of_month, 1, 2}], 1}

  """
  def tokenize(definition) when is_binary(definition) do
    definition
    |> String.to_charlist()
    |> :datetime_format_lexer.string()
  end

  def tokenize(%{number_system: _numbers, format: value}) do
    tokenize(value)
  end

  @doc """
  Parse a number format definition

  ## Arguments

  * `format_string` is a string defining how a date/time/datetime
  is to be formatted.  See `Cldr.DateTime.Formatter` for the list
  of supported format symbols.

  ## Returns

  Returns a list of function bodies which are grafted onto
  a function head in `Cldr.DateTime.Formatter` at compile time
  to produce a series of functions that process a given format
  string efficiently.

  """
  @spec compile(String.t(), module(), module()) ::
          {:ok, Cldr.Calendar.calendar()} | {:error, String.t()}
  def compile(format_string, backend, context)

  def compile("", _, _) do
    {:error, "empty format string cannot be compiled"}
  end

  def compile(nil, _, _) do
    {:error, "no format string or token list provided"}
  end

  def compile(definition, backend, context) when is_binary(definition) do
    with {:ok, tokens, _end_line} <- tokenize(definition) do
      transforms =
        Enum.map(tokens, fn {fun, _line, count} ->
          quote do
            Cldr.DateTime.Formatter.unquote(fun)(
              var!(date, unquote(context)),
              unquote(count),
              var!(locale, unquote(context)),
              unquote(backend),
              var!(options, unquote(context))
            )
          end
        end)

      {:ok, transforms}
    else
      error ->
        raise ArgumentError, "Could not parse #{inspect(definition)}: #{inspect(error)}"
    end
  end

  def compile(%{number_system: _number_system, format: value}, backend, context) do
    compile(value, backend, context)
  end

  def compile(arg, _, _) do
    raise ArgumentError, message: "No idea how to compile format: #{inspect(arg)}"
  end
end
