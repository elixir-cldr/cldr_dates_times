defmodule Cldr.DateTime.Format do
  @moduledoc """
  Manages the Date, Time and DateTime formats
  defined by CLDR.

  The functions in `Cldr.DateTime.Format` are
  primarily concerned with encapsulating the
  data from CLDR in functions that are used
  during the formatting process.
  """

  alias Cldr.Locale
  alias Cldr.LanguageTag
  alias Cldr.Config

  @type standard_formats :: %{
          full: String.t(),
          long: String.t(),
          medium: String.t(),
          short: String.t()
        }

  @type formats :: Map.t()

  @doc """
  Returns a list of all formats defined
  for the configured locales.
  """
  def format_list(config) do
    locale_names = Cldr.Config.known_locale_names(config)
    backend = config.backend

    ((known_formats(&all_date_formats(&1, backend), locale_names) ++
        known_formats(&all_time_formats(&1, backend), locale_names) ++
        known_formats(&all_date_time_formats(&1, backend), locale_names)) ++
       configured_precompile_list())
    |> Enum.reject(&is_atom/1)
    |> Enum.uniq()
  end

  def configured_precompile_list do
    Application.get_env(Config.app_name(), :precompile_datetime_formats, [])
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
  @spec calendars_for(Locale.name() | LanguageTag.t(), Cldr.backend()) ::
          [Cldr.Calendar.t(), ...]

  def calendars_for(locale, backend) do
    backend = Module.concat(backend, DateTime.Format)
    backend.calendars_for(locale)
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
  @spec gmt_format(Locale.name() | LanguageTag.t(), Cldr.backend()) :: [
          non_neg_integer | String.t(),
          ...
        ]
  def gmt_format(locale, backend) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_format(locale)
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
  @spec gmt_zero_format(Locale.name() | LanguageTag.t(), Cldr.backend()) :: String.t()
  def gmt_zero_format(locale, backend) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_zero_format(locale)
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
  @spec hour_format(Locale.name() | LanguageTag.t(), Cldr.backend()) :: {String.t(), String.t()}
  def hour_format(locale, backend) do
    backend = Module.concat(backend, DateTime.Format)
    backend.hour_format(locale)
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
  @spec date_formats(Locale.name() | LanguageTag.t(), Cldr.Calendar.t(), Cldr.backend()) ::
          standard_formats
  def date_formats(locale, calendar, backend \\ Cldr.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_formats(locale, calendar)
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
  @spec time_formats(Locale.name() | LanguageTag, Cldr.backend(), Cldr.Calendar.t()) ::
          standard_formats
  def time_formats(locale, backend, calendar) do
    backend = Module.concat(backend, DateTime.Format)
    backend.time_formats(locale, calendar)
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
  @spec date_time_formats(Locale.name() | LanguageTag.t(), Cldr.backend(), Cldr.Calendar.t()) ::
          standard_formats
  def date_time_formats(locale, backend, calendar) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_formats(locale, calendar)
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
      {:ok,
       %{
         yw_count_other: "'week' w 'of' Y",
         mmm: "LLL",
         d: "d",
         ehm: "E h:mm a",
         y_mmm: "MMM y",
         mm_md: "MMM d",
         gy_mm_md: "MMM d, y G",
         e_bhm: "E h:mm B",
         ed: "d E",
         mmm_md: "MMMM d",
         ehms: "E h:mm:ss a",
         y_qqq: "QQQ y",
         y_qqqq: "QQQQ y",
         m_ed: "E, M/d",
         md: "M/d",
         bhm: "h:mm B",
         hmv: "HH:mm v",
         y_m: "M/y",
         gy_mmm: "MMM y G",
         mmm_ed: "E, MMM d",
         y_m_ed: "E, M/d/y",
         y_mm_md: "MMM d, y",
         gy_mmm_ed: "E, MMM d, y G",
         e_hms: "E HH:mm:ss",
         e: "ccc",
         e_hm: "E HH:mm",
         yw_count_one: "'week' w 'of' Y",
         mmmmw_count_one: "'week' W 'of' MMMM",
         e_bhms: "E h:mm:ss B",
         hms: "HH:mm:ss",
         y_mmm_ed: "E, MMM d, y",
         y_md: "M/d/y",
         ms: "mm:ss",
         hmsv: "HH:mm:ss v",
         hm: "HH:mm",
         h: "HH",
         mmmmw_count_other: "'week' W 'of' MMMM",
         bh: "h B",
         m: "L",
         bhms: "h:mm:ss B",
         y_mmmm: "MMMM y",
         y: "y",
         gy: "y G"
       }}

  """
  @spec date_time_available_formats(
          Locale.name() | LanguageTag.t(),
          Cldr.Calendar.t(),
          Cldr.backend()
        ) :: formats
  def date_time_available_formats(locale, backend, calendar) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_available_formats(locale, calendar)
  end

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
  def common_date_time_format_names(backend) do
    datetime_module = Module.concat(backend, DateTime.Format)

    Cldr.known_locale_names(backend)
    |> Enum.map(&datetime_module.date_time_available_formats/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Map.keys/1)
    |> Enum.map(&MapSet.new/1)
    |> intersect_mapsets
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp known_formats(list, locale_names) do
    locale_names
    |> Enum.map(&list.(&1))
    |> List.flatten()
    |> Enum.uniq()
  end

  defp all_date_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.date_formats/2)
  end

  defp all_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.time_formats/2)
  end

  defp all_date_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.date_time_formats/2) ++
      all_formats_for(locale, backend, &datetime_backend.date_time_available_formats/2)
  end

  defp all_formats_for(locale, backend, type_function) do
    with {:ok, calendars} <- calendars_for(locale, backend) do
      Enum.map(calendars, fn calendar ->
        {:ok, calendar_formats} = type_function.(locale, calendar)
        Map.values(calendar_formats)
      end)
      |> List.flatten()
      |> Enum.uniq()
    end
  end

  defp intersect_mapsets([a, b | []]) do
    MapSet.intersection(a, b)
  end

  defp intersect_mapsets([a, b | tail]) do
    intersect_mapsets([MapSet.intersection(a, b) | tail])
  end

  # All locales define an hour_format that have the following characteristics:
  #  >  :hour and :minute only (and always both)
  #  >  :minute is always 2 digits: "mm"
  #  >  always have a sign + or -
  #  >  have either a separator of ":", "." or no separator
  # Therefore the format is always either 4 parts (with separator) or 3 parts (without separator)

  #Short format with zero minutes
  def gmt_format_type([sign, hour, _sep, "00"], :short) do
    :erlang.iolist_to_binary([sign, String.replace_leading(hour, "0", "")])
  end

  # Short format with minutes > 0
  def gmt_format_type([sign, hour, sep, minute], :short) do
    :erlang.iolist_to_binary([sign, String.replace_leading(hour, "0", ""), sep, minute])
  end

  # Long format
  def gmt_format_type([sign, hour, sep, minute], :long) do
    :erlang.iolist_to_binary([sign, hour, sep, minute])
  end

  # The case when there is no separator
  def gmt_format_type([sign, hour, minute], format_type) do
    gmt_format_type([sign, hour, "", minute], format_type)
  end
end
