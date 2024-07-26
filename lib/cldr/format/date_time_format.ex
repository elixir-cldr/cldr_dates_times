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
  alias Cldr.DateTime.Format.Compiler

  @typedoc """
  The standard formats of `:full`,
  `:long`, `:medium` and `:short` are used
  to resolve standard formats in a locale independent
  way.
  """
  @type standard_formats :: %{
          full: String.t(),
          long: String.t(),
          medium: String.t(),
          short: String.t()
        }

  @typedoc """
  A format skeleton is a string consisting of [format
  symbols](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)
  which is used to find the best match from the list of
  formats returned by `Cldr.DateTime.Format.date_time_available_formats/3`
  """
  @type format_skeleton :: atom()

  @typedoc """
  A format_id is an atom that indexes into the map returned by
  `Cldr.DateTime.Format.date_time_available_formats/3` to
  resolve a format string.
  """
  @type format_id :: atom()

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
    |> List.flatten()
  end

  @doc """
  Returns a list of calendars defined for a given locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Example

      iex> Cldr.DateTime.Format.calendars_for(:en, MyApp.Cldr)
      {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
       :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
       :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]}

  """
  @spec calendars_for(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, [Cldr.Calendar.calendar(), ...]} | {:error, {atom, String.T}}

  def calendars_for(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.calendars_for(locale)
  end

  @doc """
  Returns the GMT offset format list for a
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Example

      iex> Cldr.DateTime.Format.gmt_format(:en, MyApp.Cldr)
      {:ok, ["GMT", 0]}

  """
  @spec(
    gmt_format(Locale.locale_reference(), Cldr.backend()) ::
      {:ok, [non_neg_integer | String.t(), ...]},
    {:error, {atom, String.t()}}
  )

  def gmt_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_format(locale)
  end

  @doc """
  Returns the GMT format string for a
  for a timezone with an offset of zero for
  a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Example

      iex> Cldr.DateTime.Format.gmt_zero_format(:en, MyApp.Cldr)
      {:ok, "GMT"}

  """
  @spec gmt_zero_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def gmt_zero_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.gmt_zero_format(locale)
  end

  @doc """
  Returns the positive and negative hour format
  for a timezone offset for a given locale.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Example

      iex> Cldr.DateTime.Format.hour_format(:en, MyApp.Cldr)
      {:ok, {"+HH:mm", "-HH:mm"}}

  """
  @spec hour_format(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, {String.t(), String.t()}} | {:error, {atom, String.t()}}

  def hour_format(locale \\ Cldr.get_locale(), backend \\ Cldr.Date.default_backend()) do
    backend = Module.concat(backend, DateTime.Format)
    backend.hour_format(locale)
  end

  @doc """
  Returns a map of the standard date formats for a given
  locale and calendar.

  ### Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ### Examples:

      iex> Cldr.DateTime.Format.date_formats(:en, :gregorian, MyApp.Cldr)
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y",
        long: "MMMM d, y",
        medium: "MMM d, y",
        short: "M/d/yy"
      }}

      iex> Cldr.DateTime.Format.date_formats(:en, :buddhist, MyApp.Cldr)
      {:ok, %Cldr.Date.Formats{
        full: "EEEE, MMMM d, y G",
        long: "MMMM d, y G",
        medium: "MMM d, y G",
        short: "M/d/y GGGGG"
      }}

  """
  @spec date_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, Cldr.DateTime.Format.standard_formats()} | {:error, {atom, String.t()}}

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
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.time_formats(:en)
      {:ok, %Cldr.Time.Formats{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

      iex> Cldr.DateTime.Format.time_formats(:en, :buddhist)
      {:ok, %Cldr.Time.Formats{
        full: "h:mm:ss a zzzz",
        long: "h:mm:ss a z",
        medium: "h:mm:ss a",
        short: "h:mm a"
      }}

  """
  @spec time_formats(
          Locale.locale_name() | String.t() | LanguageTag,
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
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
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_formats(:en)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

      iex> Cldr.DateTime.Format.date_time_formats(:en, :buddhist, MyApp.Cldr)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1}, {0}",
        long: "{1}, {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"
      }}

  """
  @spec date_time_formats(
          Locale.locale_reference(),
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
  Returns a map of the standard datetime "at" formats for a given
  locale and calendar.

  An "at" format is one where the datetime is formatted with the
  date part separated from the time part by a localized version
  of "at".

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_at_formats(:en)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1} 'at' {0}",
        long: "{1} 'at' {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"}
      }

      iex> Cldr.DateTime.Format.date_time_at_formats(:en, :buddhist, MyApp.Cldr)
      {:ok, %Cldr.DateTime.Formats{
        full: "{1} 'at' {0}",
        long: "{1} 'at' {0}",
        medium: "{1}, {0}",
        short: "{1}, {0}"}
      }

  """
  @spec date_time_at_formats(
          Locale.locale_reference(),
          Cldr.Calendar.calendar(),
          Cldr.backend()
        ) ::
          {:ok, map()} | {:error, {atom, String.t()}}

  def date_time_at_formats(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_at_formats(locale, calendar)
  end

  @doc """
  Returns a map of the available datetime formats for a
  given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      iex> Cldr.DateTime.Format.date_time_available_formats(:en)
      {:ok,
       %{
         yw: %{
           other: "'week' w 'of' Y",
           one: "'week' w 'of' Y",
           pluralize: :week_of_year
         },
         GyMMMEd: "E, MMM d, y G",
         Hms: "HH:mm:ss",
         MMMMW: %{
           other: "'week' W 'of' MMMM",
           one: "'week' W 'of' MMMM",
           pluralize: :week_of_month
         },
         E: "ccc",
         MMMd: "MMM d",
         yMEd: "E, M/d/y",
         yQQQ: "QQQ y",
         Ehm: %{unicode: "E h:mm a", ascii: "E h:mm a"},
         M: "L",
         hm: %{unicode: "h:mm a", ascii: "h:mm a"},
         yM: "M/y",
         GyMMMd: "MMM d, y G",
         GyMd: "M/d/y G",
         Gy: "y G",
         Hm: "HH:mm",
         EBhms: "E h:mm:ss B",
         d: "d",
         hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
         Ed: "d E",
         Ehms: %{unicode: "E h:mm:ss a", ascii: "E h:mm:ss a"},
         EHms: "E HH:mm:ss",
         Bh: "h B",
         h: %{unicode: "h a", ascii: "h a"},
         Bhms: "h:mm:ss B",
         Hmv: "HH:mm v",
         hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"},
         yMd: "M/d/y",
         ms: "mm:ss",
         MMM: "LLL",
         y: "y",
         Bhm: "h:mm B",
         yMMM: "MMM y",
         yQQQQ: "QQQQ y",
         yMMMEd: "E, MMM d, y",
         yMMMM: "MMMM y",
         EBhm: "E h:mm B",
         Hmsv: "HH:mm:ss v",
         yMMMd: "MMM d, y",
         MEd: "E, M/d",
         EHm: "E HH:mm",
         GyMMM: "MMM y G",
         hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
         H: "HH",
         Md: "M/d",
         MMMEd: "E, MMM d",
         MMMMd: "MMMM d"
       }}

  """
  @spec date_time_available_formats(
          Locale.locale_reference(),
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

  @doc false
  @spec date_time_available_format_tokens(
          locale :: Locale.locale_reference(),
          calendar :: Cldr.Calendar.calendar(),
          backend :: Cldr.backend()
        ) :: {:ok, map()} | {:error, {atom, String.t()}}
  def date_time_available_format_tokens(
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    backend = Module.concat(backend, DateTime.Format)
    backend.date_time_available_format_tokens(locale, calendar)
  end

  @doc """
  Returns a map of the interval formats for a
  given locale and calendar.

  ## Arguments

  * `locale` is any locale returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

  * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
    The default is `:gregorian`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  ## Examples:

      Cldr.DateTime.Format.interval_formats(:en, :gregorian, MyApp.Cldr)
      => {:ok,
       %{
         bh: %{b: ["h B", "h B"], h: ["h", "h B"]},
         bhm: %{b: ["h:mm B", "h:mm B"], h: ["h:mm", "h:mm B"], m: ["h:mm", "h:mm B"]},
         d: %{d: ["d", "d"]},
         gy: %{g: ["y G", "y G"], y: ["y", "y G"]},
         ...

  """
  @spec interval_formats(
          Locale.locale_reference(),
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
  available in all known locales.

  The format types returned by `common_date_time_format_names`
  are guaranteed to be available in all known locales,

  ## Example:

      iex> Cldr.DateTime.Format.common_date_time_format_names()
      [:Bh, :Bhm, :Bhms, :E, :EBhm, :EBhms, :EHm, :EHms, :Ed, :Ehm, :Ehms, :Gy,
       :GyMMM, :GyMMMEd, :GyMMMd, :GyMd, :H, :Hm, :Hms, :Hmsv, :Hmv, :M, :MEd, :MMM,
       :MMMEd, :MMMMW, :MMMMd, :MMMd, :Md, :d, :h, :hm, :hms, :hmsv, :hmv, :ms, :y,
       :yM, :yMEd, :yMMM, :yMMMEd, :yMMMM, :yMMMd, :yMd, :yQQQ, :yQQQQ, :yw]

  """
  @spec common_date_time_format_names(backend :: Cldr.backend()) :: [format_id()]
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
      all_formats_for(locale, backend, &datetime_backend.date_time_at_formats/2) ++
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

        map =
          if is_struct(calendar_formats),
            do: Map.from_struct(calendar_formats),
            else: calendar_formats

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
        |> Enum.map(fn
          %{default: default, variant: variant} -> [default, variant]
          other -> other
        end)
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

  @doc false

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

  @doc """
  Find the best match for a requested format.

  """

  # Date/Time format symbols are defined at
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table

  @doc since: "2.19.0"
  @spec best_match(
          skeleton :: format_skeleton(),
          locale :: Locale.locale_reference(),
          calendar :: Cldr.Calendar.calendar(),
          backend :: Cldr.backend()
        ) :: {:ok, format_id()} | {:error, {module(), String.t()}}

  def best_match(
        original_skeleton,
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         skeleton = to_string(original_skeleton),
         {:ok, skeleton} <- put_preferred_time_symbols(skeleton, locale),
         {:ok, skeleton_tokens} <- Compiler.tokenize_skeleton(skeleton) do
      # match_with_day_periods? =
      #   !String.contains?(skeleton, "J")

      available_format_tokens =
        date_time_available_format_tokens(locale, calendar, backend)

      skeleton_keys =
        skeleton_tokens
        |> :proplists.get_keys()
        |> canonical_keys()

      skeleton_ordered =
        sort_tokens(skeleton_tokens)

      candidates =
        available_format_tokens
        |> Enum.filter(&filter_candidates(&1, skeleton_keys))
        |> Enum.map(&distance_from(&1, skeleton_ordered))
        |> Enum.sort(&compare_counts/2)

      case candidates do
        [] ->
          {:error, no_format_resolved_error(original_skeleton)}

        [{format_id, _} | _rest] ->
          {:ok, format_id}
      end
    end
  end

  @doc false
  def no_format_resolved_error(skeleton) do
    {
      Cldr.DateTime.UnresolvedFormat,
      "No available format resolved for #{inspect(skeleton)}"
    }
  end

  # https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons
  # For skeleton and id fields with symbols representing the same type (year, month, day, etc):
  # Most symbols have a small distance from each other.
  #   M ≅ L; E ≅ c; a ≅ b ≅ B; H ≅ k ≅ h ≅ K; ...
  # Width differences among fields, other than those marking text vs numeric, are given small
  # distance from each other.
  #   MMM ≅ MMMM
  #   MM ≅ M
  # Numeric and text fields are given a larger distance from each other.
  #   MMM ≈ MM
  # Symbols representing substantial differences (week of year vs week of month) are given a much
  # larger distance from each other.
  #   ≋ D; ...

  defp filter_candidates({_format_id, tokens}, skeleton_keys) do
    token_keys =
      tokens
      |> :proplists.get_keys()
      |> canonical_keys()

    token_keys == skeleton_keys
  end

  # Sort the tokesn in canonical order, using
  # the substiturion table.
  defp sort_tokens(tokens) do
    Enum.sort(tokens, fn {symbol_a, _}, {symbol_b, _} ->
      canonical_key(symbol_a) < canonical_key(symbol_b)
    end)
  end

  defp compare_counts({_, count_a}, {_, count_b}) do
    count_a < count_b
  end

  # These are all considered matchable since they are
  # similar. But they will have different distance weights
  # when sorting to find the best match.

  defp canonical_keys(keys) do
    keys
    |> Enum.map(&canonical_key/1)
    |> Enum.sort()
  end

  defp canonical_key(key) do
    case key do
      "L" -> "M"
      "c" -> "E"
      s when s in ["b", "B"] -> "a"
      s when s in ["k", "h", "K"] -> "H"
      other -> other
    end
  end

  # When comparing distances we want the smallest difference in each
  # token as long as we don't allow numeric symbols (like M and MM) to
  # become alpha tokens (like MMM and MMMM).

  # Note the guarantees at this point:
  # 1. The token list and the skeleton list are the same length
  # 2. The two lists are in the same semnatic order. They may not
  #    have the same symbol - but both symbols are considered
  #    substitutable for each other.

  defguard different_but_compatible(token_a, token_b)
           when (elem(token_a, 0) in ["L", "M"] and elem(token_b, 0) in ["L", "M"]) or
                  (elem(token_a, 0) in ["c", "E"] and elem(token_b, 0) in ["c", "E"]) or
                  (elem(token_a, 0) in ["a", "b", "B"] and elem(token_b, 0) in ["a", "b", "B"]) or
                  (elem(token_a, 0) in ["k", "h", "K", "H"] and
                     elem(token_b, 0) in ["k", "h", "K", "H"])

  defguard same_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) in [1, 2]) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) > 2)

  defguard different_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) > 2) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) in [1, 2])

  defp distance_from({token_id, tokens}, skeleton) do
    sorted_tokens = sort_tokens(tokens)

    distance =
      Enum.zip_reduce(sorted_tokens, skeleton, 0, fn
        # Same symbol, both numeric forms so the distance is
        # just the different in their counts
        {symbol_a, count_a}, {symbol_a, count_b}, acc
        when same_types({symbol_a, count_a}, {symbol_a, count_b}) ->
          acc + abs(count_a - count_b)

        # Same symbol, but one is numeric form, the other
        # is alpha form. Assgn a difference of 5.
        {symbol_a, count_a}, {symbol_a, count_b}, acc
        when different_types({symbol_a, count_a}, {symbol_a, count_b}) ->
          acc + 10

        # Different but compatible symbols, both of numeric
        # form.
        {symbol_a, count_a}, {symbol_b, count_b}, acc
        when different_but_compatible({symbol_a, count_a}, {symbol_b, count_b}) and
               same_types({symbol_a, count_a}, {symbol_b, count_b}) ->
          acc + abs(count_a - count_b) + 5

        # Different but compatible symbols, one numeric
        # and one alphbetic form.
        {symbol_a, count_a}, {symbol_b, count_b}, acc
        when different_but_compatible({symbol_a, count_a}, {symbol_b, count_b}) and
               different_types({symbol_a, count_a}, {symbol_b, count_b}) ->
          acc + abs(count_a - count_b) + 10

        _other_a, _other_b, acc ->
          acc + 10
      end)

    {token_id, distance}
  end

  # The time preferences are defined in
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Time_Data

  defp put_preferred_time_symbols(skeleton, locale) do
    preferred_time_symbol = preferred_time_symbol(locale)
    allowed_time_symbol = hd(allowed_time_symbols(locale))

    {:ok, replace_time_symbols(skeleton, preferred_time_symbol, allowed_time_symbol)}
  end

  defp replace_time_symbols("", _preferred, _allowed) do
    ""
  end

  defp replace_time_symbols(<<"j", rest::binary>>, preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"J", rest::binary>>, preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"C", rest::binary>>, preferred, allowed) do
    allowed <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<symbol::utf8, rest::binary>>, preferred, allowed) do
    <<symbol::utf8>> <> replace_time_symbols(rest, preferred, allowed)
  end

  @locale_preferred_time_symbol %{
    h11: "K",
    h12: "h",
    h23: "H",
    h24: "k"
  }

  # Locale's time preference takes priority
  defp preferred_time_symbol(%LanguageTag{locale: %{hc: hc}}) when is_atom(hc) do
    Map.fetch!(@locale_preferred_time_symbol, hc)
  end

  # The lookup path is:
  # 1. cldr_locale_name
  # 2. territory
  # 3. 001 ("The world")

  defp preferred_time_symbol(%LanguageTag{} = locale) do
    time_preferences(locale).preferred
  end

  defp allowed_time_symbols(locale) do
    time_preferences(locale).allowed
  end

  defp time_preferences(locale) do
    time_preferences = Cldr.Time.time_preferences()

    Map.get(time_preferences, locale.cldr_locale_name) ||
      Map.get(time_preferences, locale.territory) ||
      Map.fetch!(time_preferences, :"001")
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

  # Handle default/variant maps

  defp do_split_interval(%{default: default, variant: variant}, _acc, _left) do
    %{default: do_split_interval(default, [], ""), variant: do_split_interval(variant, [], "")}
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

  defp already_seen?("Q", acc), do: "Q" in acc || "q" in acc
  defp already_seen?("q", acc), do: "Q" in acc || "q" in acc
  defp already_seen?("L", acc), do: "L" in acc || "M" in acc
  defp already_seen?("M", acc), do: "L" in acc || "M" in acc
  defp already_seen?("E", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?("e", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?("c", acc), do: "E" in acc || "e" in acc || "c" in acc
  defp already_seen?(c, acc), do: c in acc
end
