defmodule Cldr.DateTime.Format.Compiler do
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
  Tokenize a date, time or datetime format string.

  This function is designed to produce output
  that is fed into `Cldr.DateTime.Format.Compiler.compile/3`.

  ## Arguments

  * `format_string` is a date, datetime or time format
    string.

  ## Returns

  A list of 3-tuples which represent the tokens
  of the format definition.

  ## Example

      iex> Cldr.DateTime.Format.Compiler.tokenize("yyyy/MM/dd")
      {:ok,
       [{:year, 1, 4}, {:literal, 1, "/"}, {:month, 1, 2}, {:literal, 1, "/"},
        {:day_of_month, 1, 2}], 1}

  """
  def tokenize(format_string) when is_binary(format_string) do
    format_string
    |> String.to_charlist()
    |> :date_time_format_lexer.string()
    |> maybe_add_decimal_separator()
  end

  def tokenize(%{number_system: _numbers, format: format_string}) do
    tokenize(format_string)
  end

  defp maybe_add_decimal_separator({:ok, token_list, other}) do
    {:ok, seconds_followed_by_fraction(token_list), other}
  end

  defp maybe_add_decimal_separator(other) do
    other
  end

  defp seconds_followed_by_fraction([]) do
    []
  end

  defp seconds_followed_by_fraction([{:second, _, _} = second, {:fractional_second, _, _} = fractional_second | rest]) do
    [second, {:decimal_separator, nil, nil}, fractional_second | seconds_followed_by_fraction(rest)]
  end

  defp seconds_followed_by_fraction([first | rest]) do
    [first | seconds_followed_by_fraction(rest)]
  end

  @doc """
  Parse a date, time or datetime format string.

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
          {:ok, Macro.t()} | {:error, String.t()}

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

  @doc false
  def tokenize_skeleton(token_id) when is_atom(token_id) do
    token_id
    |> Atom.to_string()
    |> tokenize_skeleton()
  end

  def tokenize_skeleton(token_id) when is_binary(token_id) do
    tokenized =
      token_id
      |> String.to_charlist()
      |> :skeleton_tokenizer.string()

    case tokenized do
      {:ok, tokens, _} ->
        {:ok, tokens}

      {:error, {_, :skeleton_tokenizer, {:illegal, content}}, _} ->
        {:error, "Illegal format string content found at: #{inspect(content)}"}
    end
  end
end
