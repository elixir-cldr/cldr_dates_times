defmodule Cldr.Date do
  @moduledoc """
  Provide an API for the localization and formatting of a `Date`
  struct or any map with the keys `:year`, `:month`,
  `:day` and `:calendar`.

  `Cldr.Date` provides support for the built-in calendar
  `Calendar.ISO`.  Use of other calendars may not produce
  the expected results.

  CLDR provides standard format strings for `Date` which
  are reresented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale may define the underlying
  format string as appropriate.
  """

  alias Cldr.DateTime.{Formatter, Format}

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  Returns either `{:ok, formatted_string}` or `{:error, reason}`.

  * `date` is a `%Date{}` struct or any map that contains the keys
  `year`, `month`, `day` and `calendar`

  * `options` is a keyword list of options for formatting.  The valid options are:
    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.  The default is `:medium`
    * `locale:` any locale returned by `Cldr.known_locales()`.  The default is `Cldr.get_current_locale()`
    * `number_system:` a number system into which the formatted date digits should be transliterated

  ## Examples

      iex> Cldr.Date.to_string ~D[2017-07-10], format: :medium
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10]
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], format: :full
      {:ok, "Monday, July 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], format: :short
      {:ok, "7/10/17"}

      iex> Cldr.Date.to_string ~D[2017-07-10], format: :short, locale: "fr"
      {:ok, "10/07/2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], format: :long, locale: "af"
      {:ok, "10 Julie 2017"}

  """
  @format_types [:short, :medium, :long, :full]

  def to_string(date, options \\ [])
  def to_string(%{year: _year, month: _month, day: _day, calendar: calendar} = date, options) do
    default_options = [format: :medium, locale: Cldr.get_current_locale()]
    options = Keyword.merge(default_options, options)

    with {:ok, locale} <- Cldr.valid_locale?(options[:locale]),
         {:ok, cldr_calendar} <- Formatter.type_from_calendar(calendar),
         {:ok, format_string} <- format_string_from_format(options[:format], locale, cldr_calendar),
         {:ok, formatted} <- Formatter.format(date, format_string, locale, options)
    do
      {:ok, formatted}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def to_string(date, _options) do
    error_return(date, [:year, :month, :day, :calendar])
  end

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  Returns either the `formatted_date` or raises an exception.

  * `date` is a `%Date{}` struct or any map that contains the keys
  `year`, `month`, `day` and `calendar`

  * `options` is a keyword list of options for formatting.  The valid options are:
    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.  The default is `:medium`
    * `locale:` any locale returned by `Cldr.known_locales()`.  The default is `Cldr.get_current_locale()`
    * `number_system:` a number system into which the formatted date digits should be transliterated

  ## Examples

      iex> Cldr.Date.to_string! ~D[2017-07-10], format: :medium
      "Jul 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10]
      "Jul 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], format: :full
      "Monday, July 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], format: :short
      "7/10/17"

      iex> Cldr.Date.to_string! ~D[2017-07-10], format: :short, locale: "fr"
      "10/07/2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], format: :long, locale: "af"
      "10 Julie 2017"

  """
  def to_string!(date, options \\ [])
  def to_string!(date, options) do
    case to_string(date, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string_from_format(format, locale, calendar) when format in @format_types do
    format_string =
      locale
      |> Format.date_formats(calendar)
      |> Map.get(format)

    {:ok, format_string}
  end

  defp format_string_from_format(%{number_system: number_system, format: format}, locale, calendar) do
    {:ok, format_string} = format_string_from_format(format, locale, calendar)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string_from_format(format, _locale, _calendar) when is_atom(format) do
    {:error, {Cldr.InvalidDateFormatType, "Invalid date format type.  " <>
              "The valid types are #{inspect @format_types}."}}
  end

  defp format_string_from_format(format_string, _locale, _calendar) when is_binary(format_string) do
    {:ok, format_string}
  end

  defp error_return(map, requirements) do
    {:error, "Invalid date. Date is a map that requires at least #{inspect requirements} fields. " <>
             "Found: #{inspect map}"}
  end
end