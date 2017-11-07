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

  @standard_formats [:short, :medium, :long, :full]
  @type standard_formats :: %{full: String.t, long: String.t, medium: String.t, short: String.t}
  @type formats :: Map.t
  @type calendar :: atom

  @doc """
  Returns a list of all formats defined
  for the configured locales.
  """
  def format_list do
    known_formats(&all_date_formats/1) ++
    known_formats(&all_time_formats/1) ++
    known_formats(&all_date_time_formats/1)
  end

  @doc """
  Returns a list of calendars defined for a given locale.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.calendars_for "en"
      [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
       :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]

  """
  @spec calendars_for(Locale.name | LanguageTag.t) :: [calendar, ...]
  def calendars_for(locale \\ Cldr.get_current_locale())
  def calendars_for(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    calendars_for(cldr_locale_name)
  end

  @doc """
  Returns a map of the standard date formats for a given locale and calendar.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_formats "en"
      %{full: "EEEE, MMMM d, y", long: "MMMM d, y", medium: "MMM d, y",
        short: "M/d/yy"}

      iex> Cldr.DateTime.Format.date_formats "en", :buddhist
      %{full: "EEEE, MMMM d, y G", long: "MMMM d, y G", medium: "MMM d, y G",
        short: "M/d/y GGGGG"}

  """
  @spec date_formats(Locale.name | LanguageTag.t, calendar) :: standard_formats
  def date_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the standard time formats for a given locale and calendar.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.time_formats "en"
      %{full: "h:mm:ss a zzzz", long: "h:mm:ss a z", medium: "h:mm:ss a",
        short: "h:mm a"}

      iex> Cldr.DateTime.Format.time_formats "en", :buddhist
      %{full: "h:mm:ss a zzzz", long: "h:mm:ss a z", medium: "h:mm:ss a",
        short: "h:mm a"}

  """
  @spec time_formats(Locale.name | LanguageTag, calendar) :: standard_formats
  def time_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    time_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the standard datetime formats for a given locale and calendar.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_formats "en"
      %{full: "{1} 'at' {0}", long: "{1} 'at' {0}", medium: "{1}, {0}",
        short: "{1}, {0}"}

      iex> Cldr.DateTime.Format.date_time_formats "en", :buddhist
      %{full: "{1} 'at' {0}", long: "{1} 'at' {0}", medium: "{1}, {0}",
        short: "{1}, {0}"}

  """
  @spec date_time_formats(Locale.name | LanguageTag, calendar) :: standard_formats
  def date_time_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_time_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns a map of the available non-standard datetime formats for a
  given locale and calendar.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_available_formats "en"
      %{m_ed: "E, M/d", md: "M/d", gy_mm_md: "MMM d, y G", ehm: "E h:mm a",
        y_m: "M/y", mm_md: "MMM d", y_mmmm: "MMMM y",
        mmmm_w_count_one: "'week' W 'of' MMMM", y_mmm: "MMM y", y_qqq: "QQQ y",
        y_mm_md: "MMM d, y", hms: "h:mm:ss a", y_mmm_ed: "E, MMM d, y",
        ehms: "E h:mm:ss a", hmsv: "h:mm:ss a v", yw_count_one: "'week' w 'of' y",
        gy: "y G", m: "L", mmm_md: "MMMM d", y_qqqq: "QQQQ y", hmv: "h:mm a v",
        mmm_ed: "E, MMM d", y_m_ed: "E, M/d/y", e_hm: "E HH:mm", h: "h a",
        e_hms: "E HH:mm:ss", hm: "h:mm a", gy_mmm_ed: "E, MMM d, y G",
        mmmm_w_count_other: "'week' W 'of' MMMM", mmm: "LLL", e: "ccc", ms: "mm:ss",
        yw_count_other: "'week' w 'of' y", ed: "d E", d: "d", y: "y", y_md: "M/d/y",
        gy_mmm: "MMM y G"}

  """
  @spec date_time_available_formats(Locale.name | LanguageTag, calendar) :: formats
  def date_time_available_formats(locale \\ Cldr.get_current_locale(), calendar \\ Kalendar.default_calendar)
  def date_time_available_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
    date_time_available_formats(cldr_locale_name, calendar)
  end

  @doc """
  Returns the postive and negative hour format
  for a timezone offset for a given locale.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.hour_format "en"
      {"+HH:mm", "-HH:mm"}

  """
  @spec hour_format(Locale.name | LanguageTag) :: {String.t, String.t}
  def hour_format(locale \\ Cldr.get_current_locale())
  def hour_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    hour_format(cldr_locale_name)
  end

  @doc """
  Returns the GMT offset format list for a
  for a timezone offset for a given locale.

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex(2)> Cldr.DateTime.Format.gmt_format "en"
      ["GMT", 0]

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

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex(3)> Cldr.DateTime.Format.gmt_zero_format "en"
      "GMT"

  """
  @spec gmt_zero_format(Locale.name | LanguageTag) :: String.t
  def gmt_zero_format(locale \\ Cldr.get_current_locale())
  def gmt_zero_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
    gmt_zero_format(cldr_locale_name)
  end

  for locale <- Cldr.known_locale_names() do
    locale_data = Cldr.Config.get_locale(locale)
    calendars = Cldr.Config.calendars_for_locale(locale_data)

    def calendars_for(unquote(locale)), do: unquote(calendars)
    def gmt_format(unquote(locale)), do: unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_format]))
    def gmt_zero_format(unquote(locale)), do: unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_zero_format]))

    hour_formats = List.to_tuple(String.split(get_in(locale_data, [:dates, :time_zone_names, :hour_format]), ";"))
    def hour_format(unquote(locale)), do: unquote(hour_formats)

    for calendar <- calendars do
      calendar_data =
        locale_data
        |> Map.get(:dates)
        |> get_in([:calendars, calendar])

      def date_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(Map.get(calendar_data, :date_formats)))
      end

      def time_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(Map.get(calendar_data, :time_formats)))
      end

      def date_time_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(
          Map.get(calendar_data, :date_time_formats)
          |> Map.take(@standard_formats)
        ))
      end

      def date_time_available_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(calendar_data, [:date_time_formats, :available_formats])))
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

  def date_formats(locale, _calendar),
    do: {:error, Locale.locale_error(locale)}
  def time_formats(locale, _calendar),
    do: {:error, Locale.locale_error(locale)}
  def date_time_formats(locale, _calendar),
    do: {:error, Locale.locale_error(locale)}
  def date_time_available_formats(locale, _calendar),
    do: {:error, Locale.locale_error(locale)}

  @doc """
  Returns a list of the date_time format types that are
  available in all locales.

  The format types returned by `common_date_time_format_names`
  are guaranteed to be available in all known locales,

  ## Example:

      iex> Cldr.DateTime.Format.common_date_time_format_names
      [:m_ed, :md, :gy_mm_md, :ehm, :y_m, :mm_md, :y_mmmm, :y_mmm, :y_qqq, :y_mm_md,
       :hms, :y_mmm_ed, :ehms, :hmsv, :gy, :m, :mmm_md, :y_qqqq, :hmv, :mmm_ed,
       :y_m_ed, :e_hm, :h, :e_hms, :hm, :gy_mmm_ed, :mmmm_w_count_other, :mmm, :e,
       :ms, :yw_count_other, :ed, :d, :y, :y_md, :gy_mmm]

  """
  def common_date_time_format_names do
    Cldr.known_locale_names
    |> Enum.map(&date_time_available_formats/1)
    |> Enum.map(&Map.keys/1)
    |> Enum.map(&MapSet.new/1)
    |> intersect_mapsets
    |> MapSet.to_list
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
    Enum.map(calendars_for(locale), fn calendar ->
      locale
      |> type_function.(calendar)
      |> Map.values
    end)
    |> List.flatten
    |> Enum.uniq
  end

  defp intersect_mapsets([a, b | []]) do
    MapSet.intersection(a,b)
  end

  defp intersect_mapsets([a, b | tail]) do
    intersect_mapsets([MapSet.intersection(a,b) | tail])
  end
end