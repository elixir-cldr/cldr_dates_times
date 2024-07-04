defmodule Cldr.DateTime do
  @moduledoc """
  Provides localization and formatting of a `t:DateTime.t/0`
  struct or any map that contains
  one or more of the keys `:year`, `:month`, `:day`, ``:hour`, `:minute` and `:second` or
  `:microsecond` with an optional `:calendar`.

  `Cldr.DateTime` provides support for the built-in calendar
  `Calendar.ISO` or any calendars defined with
  [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)

  CLDR provides standard format strings for `t:DateTime.t/0` which
  are represented by the names `:short`, `:medium`, `:long`
  and `:full`.  This allows for locale-independent
  formatting since each locale and calendar will define the underlying
  format string as appropriate.

  """

  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @format_types [:short, :medium, :long, :full]
  @default_format_type :medium
  @default_style :default
  @default_prefer :unicode

  defmodule Formats do
    @moduledoc false
    defstruct Module.get_attribute(Cldr.DateTime, :format_types)
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

  ## Arguments

  * `datetime` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, ``:hour`, `:minute` and `:second` or
    `:microsecond` with an optional `:calendar`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

    * `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format string or
      any of the keys in the map returned by `Cldr.DateTime.date_time_available_formats/3`.
      The default is `:medium`.

    * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the date part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
      then the date format is defined by the `:format` option.

    * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
      this option is used to format the time part of the date time. This option is
      only acceptable if the `:format` option is not specified, or is specified as either
      `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
      then the time format is defined by the `:format` option.

    * `:style` is either `:at` or `:default`. When set to `:at` the datetime is
      formatted with a localised string representing `<date> at <time>`. See
      `Cldr.DateTime.Format.date_time_at_formats/2`.

    * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
      formats have two variants - one using Unicode spaces (typically non-breaking space) and
      another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
      use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
      to see which formats have these variants.

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

    * `:number_system` a number system into which the formatted date digits should
      be transliterated.

    * `:era` which, if set to :variant`, will use a variant for the era if one
      is available in the requested locale. In the `:en` locale, for example, `era: :variant`
      will return `CE` instead of `AD` and `BCE` instead of `BC`.

    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM".

  ## Returns

  * `{:ok, formatted_datetime}` or

  * `{:error, reason}`

  ## Examples

      iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string(date_time)
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, locale: :en)
      {:ok, "Jan 1, 2000, 11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :long, locale: :en)
      {:ok, "January 1, 2000, 11:59:59 PM UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :hms, locale: :en)
      {:ok, "11:59:59 PM"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, locale: :en)
      {:ok, "Saturday, January 1, 2000, 11:59:59 PM GMT"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, locale: :fr)
      {:ok, "samedi 1 janvier 2000, 23:59:59 UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :en)
      {:ok, "Saturday, January 1, 2000 at 11:59:59 PM GMT"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :full, style: :at, locale: :fr)
      {:ok, "samedi 1 janvier 2000 à 23:59:59 UTC"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      {:ok, "semaine 1 (janvier)"}
      iex> Cldr.DateTime.to_string(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      {:ok, "semaine 1 de 2000"}

  """
  @spec to_string(map, Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(datetime, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string(%{calendar: Calendar.ISO} = datetime, backend, options) do
    %{datetime | calendar: Cldr.Calendar.Gregorian}
    |> to_string(backend, options)
  end

  def to_string(datetime, options, []) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(datetime, backend, options)
  end

  def to_string(%{} = datetime, backend, options)
      when is_atom(backend) and is_list(options) do
    options = normalize_options(datetime, backend, options)
    format_backend = Module.concat(backend, DateTime.Formatter)

    calendar = Map.get(datetime, :calendar, Cldr.Calendar.Gregorian)
    date = Map.put_new(datetime, :calendar, calendar)

    number_system = options.number_system
    locale = options.locale
    format = options.format
    date_format = options.date_format
    time_format = options.time_format

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, cldr_calendar} <- Cldr.DateTime.type_from_calendar(calendar),
         {:ok, _} <- Cldr.Number.validate_number_system(locale, number_system, backend),
         # {:ok, format} <- find_format(datetime, format, locale, cldr_calendar, backend),
         {:ok, format} <- apply_unicode_or_ascii_preference(format, options.prefer),
         {:ok, format_string} <- resolve_plural_format(format, date, backend, options) do
      format_backend.format(datetime, format_string, locale, options)
    end
  rescue
    e in [Cldr.DateTime.UnresolvedFormat] ->
      {:error, {e.__struct__, e.message}}
  end

  def to_string(datetime, _backend, _options) do
    error_return(datetime, [:year, :month, :day, :hour, :minute, :second, :calendar])
  end

  defp normalize_options(datetime, backend, []) do
    {locale, _backend} = Cldr.locale_and_backend_from(nil, backend)
    number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    format = formats_from_options(datetime, nil, nil, nil, @default_format_type)

    options = %{
      locale: locale,
      number_system: number_system,
      format: format,
      style: @default_style,
      prefer: @default_prefer
    }

    {:ok, options}
  end

  defp normalize_options(datetime, backend, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options[:locale], backend)

    style = options[:style] || @default_style
    prefer = options[:prefer] || @default_prefer

    format = options[:format]
    date_format = options[:date_format]
    time_format = options[:time_format]

    locale_number_system = Cldr.Number.System.number_system_from_locale(locale, backend)
    number_system = Keyword.get(options, :number_system, locale_number_system)

    {date_format, time_format} =
      formats_from_options(datetime, format, date_format, time_format, @default_format_type)

    options
    |> Map.new()
    |> Map.put(:locale, locale)
    |> Map.put(:format, format)
    |> Map.put(:date_format, date_format)
    |> Map.put(:time_format, time_format)
    |> Map.put(:style, style)
    |> Map.put(:prefer, prefer)
    |> Map.put(:number_system, number_system)

  end

  defp formats_from_options(_datetime, format, nil, nil, _default)
      when format in @format_types do
    {format, format}
  end

  defp formats_from_options(_datetime, format, nil, nil, _default)
      when is_binary(format) do
    {nil, nil}
  end

  defp formats_from_options(_datetime, format, nil, nil, _default)
      when is_atom(format) do
    {nil, nil}
  end

  defp formats_from_options(_datetime, _format, date_format, time_format, _default)
       when date_format in @format_types and time_format in @format_types do
    {date_format, time_format}
  end
  #
  # defp formats_from_options(datetime, nil, date_format, time_format, default)
  #      when not is_nil(date_format) or not is_nil(time_format) do
  #   {:error,
  #    {
  #      Cldr.DateTime.InvalidFormat,
  #      "The :date_format and :time_format options must be one of #{inspect(@format_types)}. " <>
  #        "Found #{inspect(date_format)} and #{inspect(time_format)}."
  #    }}
  # end
  #
  # defp formats_from_options(datetime, format, date_format, time_format, default)
  #      when not is_nil(date_format) or not is_nil(time_format) do
  #   {:error,
  #    {
  #      Cldr.DateTime.InvalidFormat,
  #      "The :date_format and :time_format options cannot be specified with the :format #{inspect(format)}."
  #    }}
  # end

  @doc false

  # Returns the CLDR calendar type for a calendar

  def type_from_calendar(Cldr.Calendar.Gregorian = calendar) do
    {:ok, calendar.cldr_calendar_type()}
  end

  def type_from_calendar(calendar) do
    with {:ok, calendar} <- Cldr.Calendar.validate_calendar(calendar) do
      {:ok, calendar.cldr_calendar_type()}
    end
  end

  @doc """
  Formats a DateTime according to a format string
  as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
  returning a formatted string or raising on error.

  ## Arguments

  * `datetime` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
    one or more of the keys `:year`, `:month`, `:day`, ``:hour`, `:minute` and `:second` or
    `:microsecond` with an optional `:calendar`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options for formatting.

  ## Options

    * `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format string or
      any of the keys returned by `Cldr.DateTime.Format.date_time_available_formats/0`.
      The default is `:medium`.

    * `:style` is either `:at` or `:default`. When set to `:at` the datetime is
      formatted with a localised string representing `<date> at <time>`. See
      `Cldr.DateTime.Format.date_time_at_formats/2`.

    * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of datetime
      formats have two variants - one using Unicode spaces (typically non-breaking space) and
      another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
      use cases and is not recommended. See `Cldr.DateTime.Format.date_time_available_formats/2`
      to see which formats have these variants.

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

    * `:number_system` a number system into which the formatted date digits should
      be transliterated.

    * `era: :variant` will use a variant for the era is one is available in the locale.
      In the "en" for example, the locale `era: :variant` will return "BCE" instead of "BC".

    * `period: :variant` will use a variant for the time period and flexible time period if
      one is available in the locale.  For example, in the "en" locale `period: :variant` will
      return "pm" instead of "PM".

  ## Returns

  * `formatted_datetime` or

  * raises an exception

  ## Examples

      iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, locale: :en)
      "Jan 1, 2000, 11:59:59 PM"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :long, locale: :en)
      "January 1, 2000, 11:59:59 PM UTC"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :en)
      "Saturday, January 1, 2000, 11:59:59 PM GMT"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :full, locale: :fr)
      "samedi 1 janvier 2000, 23:59:59 UTC"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :MMMMW, locale: :fr)
      "semaine 1 (janvier)"
      iex> Cldr.DateTime.to_string!(date_time, MyApp.Cldr, format: :yw, locale: :fr)
      "semaine 1 de 2000"

  """
  @spec to_string!(map, Cldr.backend() | Keyword.t(), Keyword.t()) :: String.t() | no_return

  def to_string!(datetime, backend \\ Cldr.Date.default_backend(), options \\ [])

  def to_string!(datetime, backend, options) do
    case to_string(datetime, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  # Standard format, at style
  defp format_string(format, calendar, backend, %{style: :at} = options)
       when format in @format_types do
    %LanguageTag{cldr_locale_name: locale_name} = options.locale

    with {:ok, formats} <- Format.date_time_at_formats(locale_name, calendar, backend) do
      preferred_format(formats, format, options.prefer)
    end
  end

  # Standard format, standard style
  defp format_string(format, calendar, backend, options) when format in @format_types do
    %LanguageTag{cldr_locale_name: locale_name} = options.locale

    with {:ok, formats} <- Format.date_time_formats(locale_name, calendar, backend) do
      preferred_format(formats, format, options.prefer)
    end
  end

  # Look up for the format in :available_formats
  defp format_string(format, calendar, backend, options) when is_atom(format) do
    %LanguageTag{cldr_locale_name: locale_name} = options.locale

    with {:ok, formats} <- Format.date_time_available_formats(locale_name, calendar, backend) do
      preferred_format(formats, format, options.prefer)
    end
  end

  # Straight up format string
  defp format_string(format, _calendar, _backend, _options) when is_binary(format) do
    {:ok, format}
  end

  # Format with a number system
  defp format_string(format, calendar, backend, options) do
    %{number_system: number_system, format: format} = format
    {:ok, format_string} = format_string(format, calendar, backend, options)
    {:ok, %{number_system: number_system, format: format_string}}
  end

  defp preferred_format(formats, format, prefer) do
    case Map.fetch(formats, format) do
      {:ok, format} ->
        apply_unicode_or_ascii_preference(format, prefer)

      :error ->
        {:error,
         {Cldr.DateTime.InvalidFormat,
          "Invalid datetime format #{inspect(format)}. " <>
            "The valid formats are #{inspect(formats)}."}}
    end
  end

  @doc false
  def apply_unicode_or_ascii_preference(%{unicode: _unicode, ascii: ascii}, :ascii) do
    {:ok, ascii}
  end

  def apply_unicode_or_ascii_preference(%{unicode: unicode, ascii: _ascii}, _) do
    {:ok, unicode}
  end

  def apply_unicode_or_ascii_preference(format, _) do
    {:ok, format}
  end

  @doc false
  def resolve_plural_format(%{other: _, pluralize: field} = format, date_time, backend, options) do
    pluralizer = Module.concat(backend, Number.Cardinal)

    case apply(Cldr.Calendar, field, [date_time]) do
      {_year_or_month, month_or_week} ->
        {:ok, pluralizer.pluralize(month_or_week, options.locale, format)}

      other ->
        {:ok, pluralizer.pluralize(other, options.locale, format)}
    end
  end

  def resolve_plural_format(format, _date_time, _backend, _options) do
    {:ok, format}
  end

  defp error_return(map, requirements) do
    requirements =
      requirements
      |> Enum.map(&inspect/1)
      |> Cldr.DateTime.Formatter.join_requirements()

    {:error,
     {ArgumentError,
      "Invalid DateTime. DateTime is a map that contains at least #{requirements}. " <>
        "Found: #{inspect(map)}"}}
  end
end
