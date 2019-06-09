defmodule Cldr.Time do
  @moduledoc """
  Provides localization and formatting of a `Time`
  struct or any map with the keys `:hour`, `:minute`,
  `:second` and optionlly `:microsecond`.

  `Cldr.Time` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

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

  * `locale:` any locale returned by `Cldr.known_locale_names/1`.  The default is `
    Cldr.get_locale()`

  * `number_system:` a number system into which the formatted date digits should
    be transliterated

  * `era: :variant` will use a variant for the era is one is available in the locale.
    In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".

  * `period: :variant` will use a variant for the time period and flexible time period if
    one is available in the locale.  For example, in the "en" locale `period: :variant` will
    return "pm" instead of "PM"

  ## Examples

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr
      {:ok, "7:35:13 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :short
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr"
      {:ok, "07:35:13"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :medium
      {:ok, "7:35:13 AM"}

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string datetime, MyApp.Cldr, format: :long
      {:ok, "11:59:59 PM UTC"}

  """
  @spec to_string(map, module, Keyword.t) :: {:ok, String.t} | {:error, {module, String.t}}

  def to_string(time, backend \\ Cldr.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = time, backend, options) do
    %{time | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(%{hour: _hour, minute: _minute} = time, backend, options) do
    options = Keyword.merge(default_options(), options)
    calendar = Map.get(time, :calendar) || Cldr.Calendar.Gregorian
    format_backend = Module.concat(backend, DateTime.Formatter)

    with {:ok, locale} <- Cldr.validate_locale(options[:locale]),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, format_string} <- format_string(options[:format], locale, cldr_calendar, backend),
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
    [format: :medium, locale: Cldr.get_locale(), number_system: :default]
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
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`
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

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr
      "7:35:13 AM"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :short
      "7:35 AM"

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :short, period: :variant
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr"
      "07:35:13"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :medium
      "7:35:13 AM"

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string! datetime, MyApp.Cldr, format: :long
      "11:59:59 PM UTC"

  """
  @spec to_string!(map, module, Keyword.t) :: String.t | no_return

  def to_string!(time, backend \\ Cldr.default_backend(), options \\ [])

  def to_string!(time, backend, options) do
    case to_string(time, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string(format, %LanguageTag{cldr_locale_name: locale_name}, calendar, backend)
       when format in @format_types do
    with {:ok, formats} <- Format.time_formats(locale_name, calendar, backend) do
      {:ok, Map.get(formats, format)}
    end
  end

  defp format_string(%{number_system: number_system, format: format}, locale, calendar, backend) do
    {:ok, format_string} = format_string(format, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string(format, _locale, _backend, _calendar) when is_atom(format) do
    {:error,
     {Cldr.InvalidTimeFormatType,
      "Invalid time format type.  " <> "The valid types are #{inspect(@format_types)}."}}
  end

  defp format_string(format_string, _locale, _calendar, _backend)
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
