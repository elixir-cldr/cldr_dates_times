defmodule Cldr.DateTime do
  @moduledoc """
  Provides localization and formatting of a `DateTime`
  struct or any map with the keys `:year`, `:month`,
  `:day`, `:calendar`, `:hour`, `:minute`, `:second` and optionally `:microsecond`.

  `Cldr.DateTime` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  CLDR provides standard format strings for `DateTime` which
  are reresented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale will define the underlying
  format string as appropriate.

  """

  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @format_types [:short, :medium, :long, :full]

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.DateTime, :format_types)
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  ## Arguments

  * `datetime` is a `%DateTime{}` `or %NaiveDateTime{}`struct or any map that contains the keys
    `:year`, `:month`, `:day`, `:calendar`. `:hour`, `:minute` and `:second` with optional
    `:microsecond`.

  * `options` is a keyword list of options for formatting.

  ## Options

    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string or
      any of the keys returned by `Cldr.DateTime.available_format_names`.
      The default is `:medium`

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

    * `number_system:` a number system into which the formatted date digits should
      be transliterated

    * `era: :variant` will use a variant for the era is one is available in the locale.
      In the "en" for example, the locale `era: :variant` will return "BCE" instead of "BC".

    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM"

  ## Returns

  * `{:ok, formatted_datetime}` or

  * `{:error, reason}`

  ## Examples

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string datetime
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string datetime, MyApp.Cldr, locale: "en"
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string datetime, MyApp.Cldr, format: :long, locale: "en"
      {:ok, "January 1, 2000 at 11:59:59 PM UTC"}
      iex> Cldr.DateTime.to_string datetime, MyApp.Cldr, format: :hms, locale: "en"
      {:ok, "23:59:59"}
      iex> Cldr.DateTime.to_string datetime, MyApp.Cldr, format: :full, locale: "en"
      {:ok, "Saturday, January 1, 2000 at 11:59:59 PM GMT"}
      iex> Cldr.DateTime.to_string datetime, MyApp.Cldr, format: :full, locale: "fr"
      {:ok, "samedi 1 janvier 2000 à 23:59:59 UTC"}

  """
  @spec to_string(map, module, Keyword.t()) :: {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(datetime, backend \\ Cldr.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = datetime, backend, options) do
    %{datetime | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(%{calendar: calendar} = datetime, backend, options) when is_list(options) do
    options = Keyword.merge(default_options(), options)
    format_backend = Module.concat(backend, DateTime.Formatter)

    with {:ok, locale} <- Cldr.validate_locale(options[:locale]),
         {:ok, cldr_calendar} <- type_from_calendar(calendar),
         {:ok, format_string} <- format_string(options[:format], locale, cldr_calendar, backend),
         {:ok, formatted} <- format_backend.format(datetime, format_string, locale, options) do
      {:ok, formatted}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def to_string(datetime, _backend, _options) do
    error_return(datetime, [:year, :month, :day, :hour, :minute, :second, :calendar])
  end

  defp default_options do
    [format: :medium, locale: Cldr.get_locale(), number_system: :default]
  end

  def type_from_calendar(_) do
    {:ok, :gregorian}
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
  returning a formatted string or raising on error.

  ## Arguments

  * `datetime` is a `%DateTime{}` `or %NaiveDateTime{}`struct or any map that contains the keys
    `:year`, `:month`, `:day`, `:calendar`. `:hour`, `:minute` and `:second` with optional
    `:microsecond`.

  * `options` is a keyword list of options for formatting.

  ## Options

    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string or
      any of the keys returned by `Cldr.DateTime.available_format_names` or a format string.
      The default is `:medium`

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

    * `number_system:` a number system into which the formatted date digits should
      be transliterated

    * `era: :variant` will use a variant for the era is one is available in the locale.
      In the "en" for example, the locale `era: :variant` will return "BCE" instead of "BC".

    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM"

  ## Returns

  * `formatted_datetime` or

  * raises an exception

  ## Examples

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string! datetime, MyApp.Cldr, locale: "en"
      "Jan 1, 2000, 11:59:59 PM"
      iex> Cldr.DateTime.to_string! datetime, MyApp.Cldr, format: :long, locale: "en"
      "January 1, 2000 at 11:59:59 PM UTC"
      iex> Cldr.DateTime.to_string! datetime, MyApp.Cldr, format: :full, locale: "en"
      "Saturday, January 1, 2000 at 11:59:59 PM GMT"
      iex> Cldr.DateTime.to_string! datetime, MyApp.Cldr, format: :full, locale: "fr"
      "samedi 1 janvier 2000 à 23:59:59 UTC"

  """
  @spec to_string!(map, module, Keyword.t()) :: String.t() | no_return

  def to_string!(datetime, backend \\ Cldr.default_backend(), options \\ [])

  def to_string!(datetime, backend, options) do
    case to_string(datetime, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  # Standard format
  defp format_string(format, %LanguageTag{cldr_locale_name: locale_name}, cldr_calendar, backend)
       when format in @format_types do
    with {:ok, formats} <- Format.date_time_formats(locale_name, cldr_calendar, backend) do
      {:ok, Map.get(formats, format)}
    end
  end

  # Look up for the format in :available_formats
  defp format_string(format, %LanguageTag{cldr_locale_name: locale_name}, cldr_calendar, backend)
       when is_atom(format) do
    with {:ok, formats} <-
           Format.date_time_available_formats(locale_name, cldr_calendar, backend),
         format_string <- Map.get(formats, format) do
      if format_string do
        {:ok, format_string}
      else
        {:error,
         {Cldr.InvalidDateTimeFormatType,
          "Invalid datetime format type #{inspect(format)}. " <>
            "The valid types are #{inspect(formats)}."}}
      end
    end
  end

  # Format with a number system
  defp format_string(%{number_system: number_system, format: format}, locale, calendar, backend) do
    {:ok, format_string} = format_string(format, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  # Straight up format string
  defp format_string(format_string, _locale, _calendar, _backend)
       when is_binary(format_string) do
    {:ok, format_string}
  end

  defp error_return(map, requirements) do
    {:error,
     {ArgumentError,
      "Invalid date_time. Date_time is a map that requires at least #{inspect(requirements)} fields. " <>
        "Found: #{inspect(map)}"}}
  end
end
