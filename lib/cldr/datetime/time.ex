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

  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @format_types [:short, :medium, :long, :full]

  defmodule Formats do
    defstruct Module.get_attribute(Cldr.Time, :format_types)
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  ## Returns

  * `{:ok, formatted_time}` or

  * `{:error, reason}`.

  ## Arguments

  * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
    `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

  * `options` is a keyword list of options for formatting.

  ## Options

  * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
     The default is `:medium`

  * `locale:` any locale returned by `Cldr.known_locale_names()`.  The default is `
    Cldr.get_current_locale()`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  * `era: :variant` will use a variant for the era is one is available in the locale.
    In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".

  * `period: :variant` will use a variant for the time period and flexible time period if
    one is available in the locale.  For example, in the "en" locale `period: :variant` will
    return "pm" instead of "PM"

  ## Examples

      iex> Cldr.Time.to_string ~T[07:35:13.215217]
      {:ok, "7:35:13 am"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :short
      {:ok, "7:35 am"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium, locale: "fr"
      {:ok, "07:35:13"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium
      {:ok, "7:35:13 am"}

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string datetime, format: :long
      {:ok, "11:59:59 pm UTC"}

  """

  def to_string(time, backend \\ Cldr.default_backend, options \\ [])

  def to_string(%{hour: _hour, minute: _minute} = time, backend, options) do
    options = Keyword.merge(default_options(), options)
    calendar = Map.get(time, :calendar) || Cldr.Calendar.Gregorian
    format_backend = Module.concat(backend, DateTime.Format)

    with {:ok, locale} <- Cldr.validate_locale(options[:locale]),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, format_string} <-
           format_string_from_format(options[:format], locale, backend, cldr_calendar),
         {:ok, formatted} <- format_backend.format(time, format_string, locale, options) do
      {:ok, formatted}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def to_string(time, _backend, _options) do
    error_return(time, [:hour, :minute, :second])
  end

  defp default_options do
    [format: :medium, locale: Cldr.get_locale()]
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ## Arguments

  * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
    `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

  * `options` is a keyword list of options for formatting.  The valid options are:
    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
       The default is `:medium`
    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_current_locale/0`
    * `number_system:` a number system into which the formatted date digits should
      be transliterated
    * `era: :variant` will use a variant for the era is one is available in the locale.
      In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".
    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM"

  ## Returns

  * `formatted time string` or

  * raises an exception.

  ## Examples

      iex> Cldr.Time.to_string! ~T[07:35:13.215217]
      "7:35:13 am"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :short
      "7:35 am"

      iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :short, period: :variant
      {:ok, "7:35 am"}

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :medium, locale: "fr"
      "07:35:13"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], format: :medium
      "7:35:13 am"

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string! datetime, format: :long
      "11:59:59 pm UTC"

  """
  def to_string!(time, backend, options \\ [])

  def to_string!(time, backend, options) do
    case to_string(time, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string_from_format(format, %LanguageTag{cldr_locale_name: locale_name}, backend, calendar)
       when format in @format_types do
    with {:ok, formats} <- Format.time_formats(locale_name, calendar, backend) do
      {:ok, Map.get(formats, format)}
    end
  end

  defp format_string_from_format(
         %{number_system: number_system, format: format},
         locale,
         backend,
         calendar
       ) do
    {:ok, format_string} = format_string_from_format(format, locale, backend, calendar)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string_from_format(format, _locale, _backend, _calendar) when is_atom(format) do
    {:error,
     {Cldr.InvalidTimeFormatType,
      "Invalid time format type.  " <> "The valid types are #{inspect(@format_types)}."}}
  end

  defp format_string_from_format(format_string, _locale, _backend, _calendar)
       when is_binary(format_string) do
    {:ok, format_string}
  end

  defp error_return(map, requirements) do
    {:error,
     {ArgumentError,
      "Invalid time. Time is a map that requires at least #{inspect(requirements)} fields. " <>
        "Found: #{inspect(map)}"}}
  end
end
