defmodule Cldr.Time do
  @moduledoc """
  Provides an API for the localization and formatting of a `Time`
  struct or any map with the keys `:hour`, `:minute`,
  `:second` and optionlly `:microsecond`.

  CLDR provides standard format strings for `Time` which
  are reresented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale may define the underlying
  format string as appropriate.
  """

  alias Cldr.DateTime.{Format, Formatter}
  alias Cldr.LanguageTag

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  Returns either `{:ok, formatted_time}` or `{:error, reason}`.

  * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
  `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

  * `options` is a keyword list of options for formatting.  The valid options are:

    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.  The default is `:medium`
    * `locale:` any locale returned by `Cldr.known_locales()`.  The default is `Cldr.get_current_locale()`
    * `number_system:` a number system into which the formatted date digits should be transliterated
    * `era: nil | :variant` will use a variant for the era is one is available in the locale
    * `period: nil | :variant` will use a variant for the time period and flexible time period if
      one is available in the locale

  ## Examples

      iex> Cldr.Time.to_string ~T[07:35:13.215217]
      {:ok, "7:35:13 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :short
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium, locale: "fr"
      {:ok, "07:35:13"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium
      {:ok, "7:35:13 AM"}

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string datetime, format: :long
      {:ok, "11:59:59 PM UTC"}

  """
  @format_types [:short, :medium, :long, :full]

  def to_string(time, options \\ [])
  def to_string(%{hour: _hour, minute: _minute} = time, options) do
    options = Keyword.merge(default_options(), options)
    calendar = Map.get(time, :calendar) || Calendar.ISO

    with \
      {:ok, locale} <- Cldr.validate_locale(options[:locale]),
      {:ok, cldr_calendar} <- Formatter.type_from_calendar(calendar),
      {:ok, format_string} <- format_string_from_format(options[:format], locale, cldr_calendar),
      {:ok, formatted} <- Formatter.format(time, format_string, locale, options)
    do
      {:ok, formatted}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def to_string(time, _options) do
    error_return(time, [:hour, :minute, :second])
  end

  defp default_options do
    [format: :medium, locale: Cldr.get_current_locale()]
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  Returns either the formatted time or raises an exception.

  * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
  `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

  * `options` is a keyword list of options for formatting.  The valid options are:
    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.  The default is `:medium`
    * `locale:` any locale returned by `Cldr.known_locales()`.  The default is `Cldr.get_current_locale()`
    * `number_system:` a number system into which the formatted date digits should be transliterated

  ## Examples

      iex> Cldr.Time.to_string! ~T[07:35:13.215217]
      "7:35:13 AM"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :short
      "7:35 AM"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :medium, locale: "fr"
      "07:35:13"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :medium
      "7:35:13 AM"

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string! datetime, format: :long
      "11:59:59 PM UTC"

  """
  def to_string!(time, options \\ [])
  def to_string!(time, options) do
    case to_string(time, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string_from_format(format, %LanguageTag{cldr_locale_name: locale_name}, calendar)
  when format in @format_types do
    format_string =
      locale_name
      |> Format.time_formats(calendar)
      |> Map.get(format)

    {:ok, format_string}
  end

  defp format_string_from_format(%{number_system: number_system, format: format}, locale, calendar) do
    {:ok, format_string} = format_string_from_format(format, locale, calendar)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string_from_format(format, _locale, _calendar) when is_atom(format) do
    {:error, {Cldr.InvalidTimeFormatType, "Invalid time format type.  " <>
              "The valid types are #{inspect @format_types}."}}
  end

  defp format_string_from_format(format_string, _locale, _calendar) when is_binary(format_string) do
    {:ok, format_string}
  end

  defp error_return(map, requirements) do
    {:error, {ArgumentError, "Invalid time. Time is a map that requires at least #{inspect requirements} fields. " <>
             "Found: #{inspect map}"}}
  end
end