defmodule Cldr.DateTime.Format do
  @moduledoc """
  Manages the Date, TIme and DateTime formats
  defined by CLDR.

  The functions in `Cldr.DateTime.Format` are
  primarily concerned with encapsulating the
  data from CLDR in functions that are used
  during the formatting process.
  """

  alias Cldr.Calendar, as: Kalendar
  alias Cldr.Locale
  alias Cldr.LanguageTag
  alias Cldr.Config

  @standard_formats [:short, :medium, :long, :full]

  @type standard_formats :: %{full: String.t, long: String.t, medium: String.t, short: String.t}
  @type formats :: Map.t
  @type calendar :: atom

  @doc """
  Returns a list of all formats defined
  for the configured locales.
  """
  def format_list do
    (known_formats(&all_date_formats/1) ++
    known_formats(&all_time_formats/1) ++
    known_formats(&all_date_time_formats/1)) ++
    configured_precompile_list()
    |> Enum.reject(&is_atom/1)
    |> Enum.uniq
  end

  def configured_precompile_list do
    Application.get_env(Config.app_name, :precompile_datetime_formats, [])
  end

  @doc """
  Returns a list of calendars defined for a given locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_current_locale/0`

  ## Example

      iex> Cldr.DateTime.Format.calendars_for "en"
      {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
       :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]}

  """
  @spec calendars_for(Locale.name | LanguageTag.t) :: [calendar, ...]
  def calendars_for(locale \\ Cldr.get_current_locale())
  def calendars_for(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    calendars_for(cldr_locale_name)
  end

  @doc """
  Returns a map of the standard date formats for a given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_formats "en"
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y",
        long: "MMMM d, y",
        medium: "MMM d, y",
        short: "M/d/yy"
      }}

      iex> Cldr.DateTime.Format.date_formats "en", :buddhist
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y G",
        long: "MMMM d, y G",
        medium: "MMM d, y G",
        short: "M/d/y GGGGG"
      }}

  """
  @spec date_formats(Locale.name | LanguageTag.t, calendar) :: standard_formats
  def date_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the standard time formats for a given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.time_formats "en"
      {:ok, %Cldr.Time.Formats{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

      iex> Cldr.DateTime.Format.time_formats "en", :buddhist
      {:ok, %Cldr.Time.Formats{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

  """
  @spec time_formats(Locale.name | LanguageTag, calendar) :: standard_formats
  def time_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    time_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the standard datetime formats for a given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_formats "en"
      {:ok, %Cldr.DateTime.Formats{
        full: "{1} 'at' {0}",
        long: "{1} 'at' {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

      iex> Cldr.DateTime.Format.date_time_formats "en", :buddhist
      {:ok, %Cldr.DateTime.Formats{
        full: "{1} 'at' {0}",
        long: "{1} 'at' {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

  """
  @spec date_time_formats(Locale.name | LanguageTag, calendar) :: standard_formats
  def date_time_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_time_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the available non-standard datetime formats for a
  given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_available_formats "en"
      {:ok, %{
        mm_md: "MMM d",
        mmm: "LLL",
        hmv: "h:mm a v",
        gy_mm_md: "MMM d, y G",
        ehm: "E h:mm a",
        hms: "h:mm:ss a",
        y_m: "M/y",
        gy_mmm: "MMM y G",
        mmm_md: "MMMM d",
        gy: "y G",
        e_bhm: "E h:mm B",
        e_bhms: "E h:mm:ss B",
        y_mmmm: "MMMM y",
        ehms: "E h:mm:ss a",
        hm: "h:mm a",
        yw_count_other: "'week' w 'of' Y",
        bhm: "h:mm B",
        e: "ccc",
        bhms: "h:mm:ss B",
        y_mm_md: "MMM d, y",
        y_md: "M/d/y",
        e_hm: "E HH:mm",
        h: "h a",
        y: "y",
        y_m_ed: "E, M/d/y",
        mmmmw_count_other: "'week' W 'of' MMMM",
        mmmmw_count_one: "'week' W 'of' MMMM",
        mmm_ed: "E, MMM d",
        y_mmm_ed: "E, MMM d, y",
        md: "M/d",
        gy_mmm_ed: "E, MMM d, y G",
        d: "d",
        e_hms: "E HH:mm:ss",
        hmsv: "h:mm:ss a v",
        m: "L",
        ms: "mm:ss",
        y_qqqq: "QQQQ y",
        y_mmm: "MMM y",
        m_ed: "E, M/d",
        bh: "h B",
        y_qqq: "QQQ y",
        ed: "d E",
        yw_count_one: "'week' w 'of' Y"
      }}

  """
  @spec date_time_available_formats(Locale.name | LanguageTag, calendar) :: formats
  def date_time_available_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_time_available_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_time_available_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns the postive and negative hour format
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.hour_format "en"
      {:ok, {"+HH:mm", "-HH:mm"}}

  """
  @spec hour_format(Locale.name | LanguageTag) :: {String.t, String.t}
  def hour_format(locale \\ Cldr.get_current_locale())
  def hour_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    hour_format(cldr_locale_name)
  end

  @doc """
  Returns the GMT offset format list for a
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.gmt_format "en"
      {:ok, ["GMT", 0]}

  """
  @spec gmt_format(Locale.name | LanguageTag) :: [non_neg_integer | String.t, ...]
  def gmt_format(locale \\ Cldr.get_current_locale())
  def gmt_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    gmt_format(cldr_locale_name)
  end

  @doc """
  Returns the GMT format string for a
  for a timezone with an offset of zero for
  a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.gmt_zero_format "en"
      {:ok, "GMT"}

  """
  @spec gmt_zero_format(Locale.name | LanguageTag) :: String.t
  def gmt_zero_format(locale \\ Cldr.get_current_locale())
  def gmt_zero_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    gmt_zero_format(cldr_locale_name)
  end

  for locale <- Cldr.known_locale_names() do
    locale_data = Cldr.Config.get_locale(locale)
    calendars = Cldr.Config.calendars_for_locale(locale_data)

    def calendars_for(unquote(locale)),
      do: {:ok, unquote(calendars)}
    def gmt_format(unquote(locale)),
      do: {:ok, unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_format]))}
    def gmt_zero_format(unquote(locale)),
      do: {:ok, unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_zero_format]))}

    hour_formats = List.to_tuple(String.split(get_in(locale_data, [:dates, :time_zone_names, :hour_format]), ";"))
    def hour_format(unquote(locale)),
      do: {:ok, unquote(hour_formats)}

    for calendar <- calendars do
      calendar_data =
        locale_data
        |> Map.get(:dates)
        |> get_in([:calendars, calendar])

      formats = struct(Cldr.Date.Formats, Map.get(calendar_data, :date_formats))
      def date_formats(unquote(locale), unquote(calendar)) do
        {:ok, unquote(Macro.escape(formats))}
      end

      formats = struct(Cldr.Time.Formats, Map.get(calendar_data, :time_formats))
      def time_formats(unquote(locale), unquote(calendar)) do
        {:ok, unquote(Macro.escape(formats))}
      end

      formats = struct(Cldr.DateTime.Formats, Map.get(calendar_data, :date_time_formats) |> Map.take(@standard_formats))
      def date_time_formats(unquote(locale), unquote(calendar)) do
        {:ok, unquote(Macro.escape(formats))}
      end

      formats = get_in(calendar_data, [:date_time_formats, :available_formats])
      def date_time_available_formats(unquote(locale), unquote(calendar)) do
        {:ok, unquote(Macro.escape(formats))}
      end
    end

    def date_formats(unquote(locale), calendar),
      do: {:error, Kalendar.calendar_error(calendar)}
    def time_formats(unquote(locale), calendar),
      do: {:error, Kalendar.calendar_error(calendar)}
    def date_time_formats(unquote(locale), calendar),
      do: {:error, Kalendar.calendar_error(calendar)}
    def date_time_available_formats(unquote(locale), calendar),
      do: {:error, Kalendar.calendar_error(calendar)}
  end

  def calendars_for(locale), do: {:error, Locale.locale_error(locale)}
  def gmt_format(locale), do: {:error, Locale.locale_error(locale)}
  def gmt_zero_format(locale), do: {:error, Locale.locale_error(locale)}
  def hour_format(locale), do: {:error, Locale.locale_error(locale)}
  def date_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def time_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def date_time_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}
  def date_time_available_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}

  @doc """
  Returns a list of the date_time format types that are
  available in all locales.

  The format types returned by `common_date_time_format_names`
  are guaranteed to be available in all known locales,

  ## Example:

      iex> Cldr.DateTime.Format.common_date_time_format_names
      [:bh, :bhm, :bhms, :d, :e, :e_bhm, :e_bhms, :e_hm, :e_hms, :ed, :ehm,
      :ehms, :gy, :gy_mm_md, :gy_mmm, :gy_mmm_ed, :h, :hm, :hms, :hmsv,
      :hmv, :m, :m_ed, :md, :mm_md, :mmm, :mmm_ed, :mmm_md,
      :mmmmw_count_other, :ms, :y, :y_m, :y_m_ed, :y_md, :y_mm_md, :y_mmm,
      :y_mmm_ed, :y_mmmm, :y_qqq, :y_qqqq, :yw_count_other]

  """
  def common_date_time_format_names do
    Cldr.known_locale_names
    |> Enum.map(&date_time_available_formats/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Map.keys/1)
    |> Enum.map(&MapSet.new/1)
    |> intersect_mapsets
    |> MapSet.to_list
    |> Enum.sort
  end

  defp known_formats(list) do
    Cldr.known_locale_names()
    |> Enum.map(&(list.(&1)))
    |> List.flatten
    |> Enum.uniq
  end

  defp all_date_formats(locale) do
    all_formats_for(locale, &date_formats/2)
  end

  defp all_time_formats(locale) do
    all_formats_for(locale, &time_formats/2)
  end

  defp all_date_time_formats(locale) do
    all_formats_for(locale, &date_time_formats/2) ++
    all_formats_for(locale, &date_time_available_formats/2)
  end

  defp all_formats_for(locale, type_function) do
    with {:ok, calendars} <- calendars_for(locale) do
      Enum.map(calendars, fn calendar ->
        {:ok, calendar_formats} = type_function.(locale, calendar)
        Map.values(calendar_formats)
      end)
      |> List.flatten
      |> Enum.uniq
    end
  end

  defp intersect_mapsets([a, b | []]) do
    MapSet.intersection(a,b)
  end

  defp intersect_mapsets([a, b | tail]) do
    intersect_mapsets([MapSet.intersection(a,b) | tail])
  end
end