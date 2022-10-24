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

  @type standard_formats :: %{
          full: String.t(),
          long: String.t(),
          medium: String.t(),
          short: String.t()
        }

  @type formats :: Cldr.Calendar.calendar()

  @doc false
  def format_list(config) do
    locale_names = Cldr.Locale.Loader.known_locale_names(config)
    backend = config.backend

    ((known_formats(&all_date_formats(&1, backend), locale_names) ++
        known_formats(&all_time_formats(&1, backend), locale_names) ++
        known_formats(&all_date_time_formats(&1, backend), locale_names) ++
        known_formats(&all_interval_formats(&1, backend), locale_names)) ++
       config.precompile_date_time_formats ++ precompile_interval_formats(config))
    |> only_compilable_formats()
    |> Enum.uniq()
    |> Enum.reject(&is_atom/1)
  end

  defp only_compilable_formats(formats) do
    Enum.reduce(formats, [], fn
      f, acc when is_binary(f) -> [f | acc]
      %{number_system: _} = format, acc -> [format | acc]
      map, acc when is_map(map) -> Map.values(map) ++ acc
      list, acc when is_list(list) -> acc
    end)
  end

  defp precompile_interval_formats(config) do
    config.precompile_interval_formats
    |> Enum.flat_map(&split_interval!/1)
  end

  @doc """
  Returns a list of calendars defined for a given locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

  ## Example

      iex> Cldr.DateTime.Format.calendars_for "en", MyApp.Cldr
      {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
       :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]}

  """
  @spec calendars_for(Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, [Cldr.Calendar.calendar(), ...]} | {:error, {atom, String.T}}

  def calendars_for(locale, backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.calendars_for(locale)
  end

  @doc """
  Returns the GMT offset format list for a
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.gmt_format "en", MyApp.Cldr
      {:ok, ["GMT", 0]}

  """
  @spec(
    gmt_format(Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
      {:ok, [non_neg_integer | String.t(), ...]},
    {:error, {atom, String.t()}}
  )

  def gmt_format(locale, backend \\ Cldr.Date.default_backend()) do
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

      iex> Cldr.DateTime.Format.gmt_zero_format "en", MyApp.Cldr
      {:ok, "GMT"}

  """
  @spec gmt_zero_format(Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def gmt_zero_format(locale, backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_zero_format(locale)
  end

  @doc """
  Returns the positive and negative hour format
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  ## Example

      iex> Cldr.DateTime.Format.hour_format "en", MyApp.Cldr
      {:ok, {"+HH:mm", "-HH:mm"}}

  """
  @spec hour_format(Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, {String.t(), String.t()}} | {:error, {atom, String.t()}}

  def hour_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
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

      iex> Cldr.DateTime.Format.date_formats "en", :gregorian, MyApp.Cldr
      {:ok, %Cldr.Date.Styles{
        full: "EEEE, MMMM d, y",
        long: "MMMM d, y",
        medium: "MMM d, y",
        short: "M/d/yy"
      }}

      iex> Cldr.DateTime.Format.date_formats "en", :buddhist, MyApp.Cldr
      {:ok, %Cldr.Date.Styles{
        full: "EEEE, MMMM d, y G",
        long: "MMMM d, y G",
        medium: "MMM d, y G",
        short: "M/d/y GGGGG"
      }}

  """
  @spec date_formats(
          Locale.locale_name() | LanguageTag.t(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, standard_formats} | {:error, {atom, String.t()}}

  def date_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
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
      {:ok, %Cldr.Time.Styles{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

      iex> Cldr.DateTime.Format.time_formats "en", :buddhist
      {:ok, %Cldr.Time.Styles{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

  """
  @spec time_formats(Locale.locale_name() | LanguageTag, Cldr.Calendar.calendar(), Cldr.backend()) ::
          {:ok, standard_formats} | {:error, {atom, String.t()}}

  def time_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
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
      {:ok, %Cldr.DateTime.Styles{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

      iex> Cldr.DateTime.Format.date_time_formats "en", :buddhist, MyApp.Cldr
      {:ok, %Cldr.DateTime.Styles{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

  """
  @spec date_time_formats(
          Locale.locale_name() | LanguageTag.t(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
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
         d: "d",
         y_m_ed: "E, M/d/y",
         y_mmm_ed: "E, MMM d, y",
         mmmmw: %{one: "'week' W 'of' MMMM", other: "'week' W 'of' MMMM"},
         h: "HH",
         e_bhms: "E h:mm:ss B",
         y_md: "M/d/y",
         gy_mm_md: "MMM d, y G",
         gy: "y G",
         y_mmmm: "MMMM y",
         ed: "d E",
         mmm_ed: "E, MMM d",
         hms: "h:mm:ss a",
         e_hm: "E HH:mm",
         mmm_md: "MMMM d",
         mmm: "LLL",
         bhms: "h:mm:ss B",
         y: "y",
         e_bhm: "E h:mm B",
         gy_mmm: "MMM y G",
         y_qqq: "QQQ y",
         ms: "mm:ss",
         e_hms: "E HH:mm:ss",
         ehms: "E h:mm:ss a",
         bhm: "h:mm B",
         y_m: "M/y",
         gy_mmm_ed: "E, MMM d, y G",
         y_qqqq: "QQQQ y",
         ehm: "E h:mm a",
         y_mm_md: "MMM d, y",
         hmv: "h:mm a v",
         mm_md: "MMM d",
         m_ed: "E, M/d",
         bh: "h B",
         hmsv: "h:mm:ss a v",
         gy_md: "M/d/y G",
         md: "M/d",
         hm: "h:mm a",
         m: "L",
         yw: %{one: "'week' w 'of' Y", other: "'week' w 'of' Y"},
         y_mmm: "MMM y",
         e: "ccc"
       }}

  """
  @spec date_time_available_formats(
          Locale.locale_name() | LanguageTag.t(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_available_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_available_formats(locale, calendar)
  end

  @doc """
  Returns a map of the interval formats for a
  given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`

  ## Examples:

      Cldr.DateTime.Format.interval_formats "en", :gregorian, MyApp.Cldr
      => {:ok,
       %{
         bh: %{b: ["h B", "h B"], h: ["h", "h B"]},
         bhm: %{b: ["h:mm B", "h:mm B"], h: ["h:mm", "h:mm B"], m: ["h:mm", "h:mm B"]},
         d: %{d: ["d", "d"]},
         gy: %{g: ["y G", "y G"], y: ["y", "y G"]},
         ...

  """
  @spec interval_formats(
          Locale.locale_name() | LanguageTag.t(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}

  def interval_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_interval_formats(locale, calendar)
  end

  @doc """
  Returns a list of the date_time format types that are
  available in all locales.

  The format types returned by `common_date_time_format_names`
  are guaranteed to be available in all known locales,

  ## Example:

      iex> Cldr.DateTime.Format.common_date_time_format_names
      [:bh, :bhm, :bhms, :d, :e, :e_bhm, :e_bhms, :e_hm, :e_hms, :ed, :ehm,
      :ehms, :gy, :gy_md, :gy_mm_md, :gy_mmm, :gy_mmm_ed, :h, :hm, :hms, :hmsv,
      :hmv, :m, :m_ed, :md, :mm_md, :mmm, :mmm_ed, :mmm_md,
      :mmmmw, :ms, :y, :y_m, :y_m_ed, :y_md, :y_mm_md, :y_mmm,
      :y_mmm_ed, :y_mmmm, :y_qqq, :y_qqqq, :yw]

  """
  def common_date_time_format_names(backend \\ Cldr.Date.default_backend()) do
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
    |> Enum.reduce([], fn l, acc -> acc ++ list.(l) end)
    |> Enum.uniq()
  end

  @doc false
  def all_date_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.date_formats/2)
  end

  @doc false
  def all_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_formats_for(locale, backend, &datetime_backend.time_formats/2)
  end

  @doc false
  def all_date_time_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)

    all_formats_for(locale, backend, &datetime_backend.date_time_formats/2) ++
      all_formats_for(locale, backend, &datetime_backend.date_time_available_formats/2)
  end

  @doc false
  def all_interval_formats(locale, backend) do
    datetime_backend = Module.concat(backend, DateTime.Format)
    all_interval_formats_for(locale, backend, &datetime_backend.date_time_interval_formats/2)
  end

  @doc false
  def all_formats_for(locale, backend, type_function) do
    with {:ok, calendars} <- calendars_for(locale, backend) do
      Enum.reduce(calendars, [], fn calendar, acc ->
        {:ok, calendar_formats} = type_function.(locale, calendar)
        map = if is_struct(calendar_formats), do: Map.from_struct(calendar_formats), else: calendar_formats
        acc ++ Map.values(map)
      end)
      |> Enum.uniq()
    end
  end

  @doc false
  def all_interval_formats_for(locale, backend, type_function) do
    with {:ok, calendars} <- calendars_for(locale, backend) do
      Enum.map(calendars, fn calendar ->
        {:ok, calendar_formats} = type_function.(locale, calendar)

        calendar_formats
        |> Map.values()
        |> Enum.filter(&is_map/1)
        |> Enum.flat_map(&Map.values/1)
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

  # Short format with zero minutes
  def gmt_format_type([sign, hour, _sep, "00"], :short) do
    [sign, String.replace_leading(hour, "0", "")]
  end

  # Short format with minutes > 0
  def gmt_format_type([sign, hour, sep, minute], :short) do
    [sign, String.replace_leading(hour, "0", ""), sep, minute]
  end

  # Long format
  def gmt_format_type([sign, hour, sep, minute], :long) do
    [sign, hour, sep, minute]
  end

  # The case when there is no separator
  def gmt_format_type([sign, hour, minute], format_type) do
    gmt_format_type([sign, hour, "", minute], format_type)
  end

  ### Helpers

  @doc false

  # Used during compilation to split an interval into
  # the from and to parts

  def split_interval(interval) do
    case do_split_interval(interval, [], "") do
      {:error, reason} -> {:error, reason}
      success -> {:ok, success}
    end
  end

  @doc false
  def split_interval!(interval) do
    case do_split_interval(interval, [], "") do
      {:error, {exception, reason}} -> raise exception, reason
      success -> success
    end
  end

  defp do_split_interval("", _acc, left) do
    {:error,
     {Cldr.DateTime.IntervalFormatError, "Invalid datetime interval format #{inspect(left)}"}}
  end

  # Quoted strings pass through. This assumes the quotes
  # are correctly closed.

  @literal "'"
  defp do_split_interval(<<@literal, rest::binary>>, acc, left) do
    [literal, rest] = String.split(rest, @literal, parts: 2)
    do_split_interval(rest, acc, left <> @literal <> literal <> @literal)
  end

  # characters that are not format characters
  # pass through

  defp do_split_interval(<<c::utf8, rest::binary>>, acc, left)
       when c not in ?a..?z and c not in ?A..?Z do
    do_split_interval(rest, acc, left <> List.to_string([c]))
  end

  # Handle format characters that repeat up to a maximum of
  # 5 times

  defp do_split_interval(
         <<c::binary-1, c::binary-1, c::binary-1, c::binary-1, c::binary-1, rest::binary>>,
         acc,
         left
       ) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 5) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 5))
    end
  end

  defp do_split_interval(
         <<c::binary-1, c::binary-1, c::binary-1, c::binary-1, rest::binary>>,
         acc,
         left
       ) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 4) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 4))
    end
  end

  defp do_split_interval(<<c::binary-1, c::binary-1, c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 3) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 3))
    end
  end

  defp do_split_interval(<<c::binary-1, c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, String.duplicate(c, 2) <> rest]
    else
      do_split_interval(rest, [c | acc], left <> String.duplicate(c, 2))
    end
  end

  defp do_split_interval(<<c::binary-1, rest::binary>>, acc, left) do
    if already_seen?(c, acc) do
      [left, c <> rest]
    else
      do_split_interval(rest, [c | acc], left <> c)
    end
  end

  # Per the updated spec we treat format characters as equivalent to their
  # standalone format for the purposes of splitting. ie we treat "L" == "M"
  #
  # Equivalence table:
  # Quarter:  Q, q
  # Month: L, M
  # Week Day: E, e, c

  defp already_seen?("Q", acc), do: ("Q" in acc) || ("q" in acc)
  defp already_seen?("q", acc), do: ("Q" in acc) || ("q" in acc)
  defp already_seen?("L", acc), do: ("L" in acc) || ("M" in acc)
  defp already_seen?("M", acc), do: ("L" in acc) || ("M" in acc)
  defp already_seen?("E", acc), do: ("E" in acc) || ("e" in acc) || ("c" in acc)
  defp already_seen?("e", acc), do: ("E" in acc) || ("e" in acc) || ("c" in acc)
  defp already_seen?("c", acc), do: ("E" in acc) || ("e" in acc) || ("c" in acc)
  defp already_seen?(c, acc), do: c in acc
end
