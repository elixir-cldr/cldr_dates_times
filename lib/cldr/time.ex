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

  @style_types [:short, :medium, :long, :full]
  @default_type :medium

  defmodule Styles do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.Time, :style_types)
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

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

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
      {:ok, "7:35:13 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :short
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr"
      {:ok, "07:35:13"}

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :medium
      {:ok, "7:35:13 AM"}

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string datetime, MyApp.Cldr, format: :long
      {:ok, "11:59:59 PM UTC"}

  """
  @spec to_string(map, Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = time, backend, options) do
    %{time | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(time, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(time, backend, options)
  end

  def to_string(%{hour: _hour, minute: _minute} = time, backend, options) do
    options = normalize_options(backend, options)
    calendar = Map.get(time, :calendar) || Cldr.Calendar.Gregorian
    format_backend = Module.concat(backend, DateTime.Formatter)
    number_system = Map.get(options, :number_system)

    with {:ok, locale} <- Cldr.validate_locale(options[:locale], backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         {:ok, format_string} <- format_string(options[:format], locale, cldr_calendar, backend),
         {:ok, formatted} <- format_backend.format(time, format_string, locale, options) do
      {:ok, formatted}
    end
  rescue
    e in [Cldr.DateTime.UnresolvedFormat] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(time, _backend, _options) do
    error_return(time, [:hour, :minute, :second])
  end

  # TODO deprecate :style in version 3.0
  defp normalize_options(_backend, %{} = options) do
    options
  end

  defp normalize_options(backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)

    %{locale: locale, number_system: number_system, format: @default_type}
  end

  defp normalize_options(backend, options) do
    {locale, _backend} = Cldr.locale_and_backend_from(options[:locale], backend)
    format = options[:format] || options[:stylet] || @default_type
    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)

    options
    |> Keyword.put(:locale, locale)
    |> Keyword.put(:format, format)
    |> Keyword.delete(:style)
    |> Keyword.put_new(:number_system, number_system)
    |> Map.new()
  end

  @doc """
  Formats a time according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

  ## Arguments

  * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
    `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

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

    * `era: :variant` will use a variant for the era is one is available in the locale.
      In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".

    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM"

  ## Returns

  * `formatted_time_string` or

  * raises an exception.

  ## Examples

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr
      "7:35:13 AM"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :short
      "7:35 AM"

      iex> Cldr.Time.to_string ~T[07:35:13.215217], MyApp.Cldr, format: :short, period: :variant
      {:ok, "7:35 AM"}

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :medium, locale: "fr"
      "07:35:13"

      iex> Cldr.Time.to_string! ~T[07:35:13.215217], MyApp.Cldr, format: :medium
      "7:35:13 AM"

      iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.Time.to_string! datetime, MyApp.Cldr, format: :long
      "11:59:59 PM UTC"

  """
  @spec to_string!(map, Cldr.backend() | Keyword.t(), Keyword.t()) :: String.t() | no_return

  def to_string!(time, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(time, backend, options) do
    case to_string(time, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp format_string(style, %LanguageTag{cldr_locale_name: locale_name}, calendar, backend)
       when style in @style_types do
    with {:ok, styles} <- Format.time_formats(locale_name, calendar, backend) do
      {:ok, Map.get(styles, style)}
    end
  end

  defp format_string(%{number_system: number_system, format: style}, locale, calendar, backend) do
    {:ok, format_string} = format_string(style, locale, calendar, backend)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp format_string(style, _locale, _backend, _calendar) when is_atom(style) do
    {:error,
     {Cldr.DateTime.InvalidStyle,
      "Invalid time format style.  " <> "The valid styles are #{inspect(@style_types)}."}}
  end

  defp format_string(format_string, _locale, _calendar, _backend)
       when is_binary(format_string) do
    {:ok, format_string}
  end

  @doc """
  Return the preferred time format for a locale.

  ## Arguments

  * `language_tag` is any language tag returned by `Cldr.Locale.new/2`
    or any `locale_name` returned by `Cldr.known_locale_names/1`

  ## Returns

  * The hour format as an atom to be used for localization purposes. The
    return value is used as a function name in `Cldr.DateTime.Formatter`

  ## Notes

  * The `hc` key of the `u` extension is honoured and will
    override the default preferences for a locale or territory.
    See the last example below.

  * Different locales and territories present the hour
    of day in different ways. These are represented
    in `Cldr.DateTime.Formatter` in the following way:

  | Symbol  | Midn.  |  Morning  | Noon  |  Afternoon | Midn. |
  | :----:  | :---:  | :-----:   | :--:  | :--------: | :---: |
  |   h     |  12    | 1...11    |  12   |   1...11   |  12   |
  |   K     |   0    | 1...11    |   0   |   1...11   |   0   |
  |   H     |   0    | 1...11    |  12   |  13...23   |   0   |
  |   k     |  24    | 1...11    |  12   |  13...23   |  24   |

  ## Examples

      iex> Cldr.Time.hour_format_from_locale "en-AU"
      :h12

      iex> Cldr.Time.hour_format_from_locale "fr"
      :h23

      iex> Cldr.Time.hour_format_from_locale "fr-u-hc-h12"
      :h12

  """
  def hour_format_from_locale(%LanguageTag{locale: %{hc: hour_cycle}})
      when not is_nil(hour_cycle) do
    hour_cycle
  end

  def hour_format_from_locale(%LanguageTag{} = locale) do
    preferences = time_preferences()
    territory = Cldr.Locale.territory_from_locale(locale)

    preference =
      preferences[locale.cldr_locale_name] ||
        preferences[territory] ||
        preferences[Cldr.the_world()]

    Map.fetch!(time_symbols(), preference.preferred)
  end

  def hour_format_from_locale(locale_name, backend \\ Cldr.Date.default_backend()) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      hour_format_from_locale(locale)
    end
  end

  @time_preferences Cldr.Config.time_preferences()
  defp time_preferences do
    @time_preferences
  end

  # | Symbol   | Midn.  |  Morning  | Noon  | Afternoon  | Midn. | Code
  # | :----:   | :---:  | :-----:   | :--:  | :--------: | :---: | :--:
  # |   h      |  12    | 1...11    |  12   |   1...11   |  12   | :h12
  # |   K      |   0    | 1...11    |   0   |   1...11   |   0   | :h11
  # |   H      |   0    | 1...11    |  12   |  13...23   |   0   | :h23
  # |   k      |  24    | 1...11    |  12   |  13...23   |  24   | :h24
  #
  defp time_symbols do
    %{
      "h" => :h12, # :hour_1_12,
      "K" => :h11, # :hour_0_11,
      "H" => :h23, # :hour_0_23,
      "k" => :h24, # :hour_1_24.
    }
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Invalid time. Time is a map that contains at least #{requirements} fields. " <>
        "Found: #{inspect(map)}"}}
  end
end
