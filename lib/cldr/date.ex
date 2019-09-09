defmodule Cldr.Date do
  @moduledoc """
  Provides localization and formatting of a `Date`
  struct or any map with the keys `:year`, `:month`,
  `:day` and `:calendar`.

  `Cldr.Date` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  CLDR provides standard format strings for `Date` which
  are reresented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale may define the underlying
  format string as appropriate.

  """

  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @format_types [:short, :medium, :long, :full]

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.Date, :format_types)
  end

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  ## Arguments

  * `date` is a `%Date{}` struct or any map that contains the keys
    `year`, `month`, `day` and `calendar`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options for formatting.  The valid options are:

  ## Options

    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
      The default is `:medium`

    * `locale:` any locale returned by `Cldr.known_locale_names/1`.
      The default is `Cldr.get_locale()`.

    * `number_system:` a number system into which the formatted date digits
      should be transliterated

  ## Returns

  * `{:ok, formatted_string}` or

  * `{:error, reason}`

  ## Examples

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, format: :medium, locale: "en"
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, locale: "en"
      {:ok, "Jul 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, format: :full, locale: "en"
      {:ok, "Monday, July 10, 2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, format: :short, locale: "en"
      {:ok, "7/10/17"}

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, format: :short, locale: "fr"
      {:ok, "10/07/2017"}

      iex> Cldr.Date.to_string ~D[2017-07-10], MyApp.Cldr, format: :long, locale: "af"
      {:ok, "10 Julie 2017"}

  """
  @spec to_string(map, Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(date, backend \\ Cldr.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = date, backend, options) do
    %{date | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(date, options, []) when is_list(options) do
    to_string(date, Cldr.default_backend(), options)
  end

  def to_string(%{calendar: calendar} = date, backend, options) do
    options = Keyword.merge(default_options(), options)
    format_backend = Module.concat(backend, DateTime.Formatter)

    with {:ok, locale} <- Cldr.validate_locale(options[:locale], backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, format_string} <- format_string(options[:format], locale, cldr_calendar, backend),
         {:ok, formatted} <- format_backend.format(date, format_string, locale, options) do
      {:ok, formatted}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    e in [Cldr.DateTime.UnresolvedFormat] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(date, _backend, _options) do
    error_return(date, [:year, :month, :day, :calendar])
  end

  defp default_options do
    [format: :medium, locale: Cldr.get_locale(), number_system: :default]
  end

  @doc """
  Formats a date according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  ## Arguments

  * `date` is a `%Date{}` struct or any map that contains the keys
    `year`, `month`, `day` and `calendar`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

    * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
      The default is `:medium`

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

    * `number_system:` a number system into which the formatted date digits should
      be transliterated

  ## Returns

  * `formatted_date` or

  * raises an exception.

  ## Examples

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, format: :medium, locale: "en"
      "Jul 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, locale: "en"
      "Jul 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, format: :full,locale: "en"
      "Monday, July 10, 2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, format: :short, locale: "en"
      "7/10/17"

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, format: :short, locale: "fr"
      "10/07/2017"

      iex> Cldr.Date.to_string! ~D[2017-07-10], MyApp.Cldr, format: :long, locale: "af"
      "10 Julie 2017"

  """
  @spec to_string!(map, Cldr.backend() | Keyword.t(), Keyword.t()) :: String.t() | no_return

  def to_string!(date, backend \\ Cldr.default_backend(), options \\ [])

  def to_string!(date, backend, options) do
    case to_string(date, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string(format, %LanguageTag{cldr_locale_name: locale_name}, calendar, backend)
       when format in @format_types do
    with {:ok, date_formats} <- Format.date_formats(locale_name, calendar, backend) do
      {:ok, Map.get(date_formats, format)}
    end
  end

  defp format_string(%{number_system: number_system, format: format}, locale, calendar, backend) do
    {:ok, format_string} = format_string(format, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string(format, _locale, _calendar, _backend) when is_atom(format) do
    {:error,
     {Cldr.InvalidDateFormatType,
      "Invalid date format type.  " <> "The valid types are #{inspect(@format_types)}."}}
  end

  defp format_string(format_string, _locale, _calendar, _backend)
       when is_binary(format_string) do
    {:ok, format_string}
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Invalid date. Date is a map that contains at least #{requirements}. " <>
        "Found: #{inspect(map)}"}}
  end
end
