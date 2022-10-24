defmodule Cldr.DateTime.Format.Backend do
  @moduledoc false

  def define_date_time_format_module(config) do
    backend = config.backend
    config = Macro.escape(config)
    module = inspect(__MODULE__)

    quote location: :keep, bind_quoted: [config: config, backend: backend, module: module] do
      defmodule DateTime.Format do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Manages the Date, TIme and DateTime formats
          defined by CLDR.

          The functions in `Cldr.DateTime.Format` are
          primarily concerned with encapsulating the
          data from CLDR in functions that are used
          during the formatting process.
          """
        end

        alias Cldr.Locale
        alias Cldr.LanguageTag
        alias Cldr.Config
        alias Cldr.DateTime.Format

        @standard_formats [:short, :medium, :long, :full]

        @doc "A struct of the format types and formats"
        @type formats :: map()

        @doc "The CLDR calendar type as an atome"
        @type calendar :: atom()

        @doc """
        Returns a list of calendars defined for a given locale.

        ## Arguments

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

        ## Example

            iex> #{inspect(__MODULE__)}.calendars_for "en"
            {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
             :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
             :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]}

        """
        @spec calendars_for(Locale.locale_name() | LanguageTag.t()) ::
                {:ok, [calendar, ...]} | {:error, {module(), String.t()}}

        def calendars_for(locale \\ unquote(backend).get_locale())

        def calendars_for(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          calendars_for(cldr_locale_name)
        end

        def calendars_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            calendars_for(locale)
          end
        end

        @doc """
        Returns a map of the standard date formats for a given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_formats "en"
            {:ok, %Cldr.Date.Styles{
              full: "EEEE, MMMM d, y",
              long: "MMMM d, y",
              medium: "MMM d, y",
              short: "M/d/yy"
            }}

            iex> #{inspect(__MODULE__)}.date_formats "en", :buddhist
            {:ok, %Cldr.Date.Styles{
              full: "EEEE, MMMM d, y G",
              long: "MMMM d, y G",
              medium: "MMM d, y G",
              short: "M/d/y GGGGG"
            }}

        """
        @spec date_formats(Locale.locale_name() | LanguageTag.t(), calendar) ::
                {:ok, map()} | {:error, {module(), String.t()}}

        def date_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          date_formats(cldr_locale_name, calendar)
        end

        def date_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the standard time formats for a given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
        The default is `:gregorian`

        ## Examples:

            iex> #{inspect(__MODULE__)}.time_formats "en"
            {:ok, %Cldr.Time.Styles{
              full: "h:mm:ss a zzzz",
              long: "h:mm:ss a z",
              medium: "h:mm:ss a",
              short: "h:mm a"
            }}

            iex> #{inspect(__MODULE__)}.time_formats "en", :buddhist
            {:ok, %Cldr.Time.Styles{
              full: "h:mm:ss a zzzz",
              long: "h:mm:ss a z",
              medium: "h:mm:ss a",
              short: "h:mm a"
            }}

        """
        @spec time_formats(Locale.locale_name() | LanguageTag.t(), calendar) ::
                {:ok, map()} | {:error, {module(), String.t()}}

        def time_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          time_formats(cldr_locale_name, calendar)
        end

        def time_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            time_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the standard datetime formats for a given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
        The default is `:gregorian`

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_formats "en"
            {:ok, %Cldr.DateTime.Styles{
              full: "{1}, {0}",
              long: "{1}, {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"
            }}

            iex> #{inspect(__MODULE__)}.date_time_formats "en", :buddhist
            {:ok, %Cldr.DateTime.Styles{
              full: "{1}, {0}",
              long: "{1}, {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"
            }}

        """
        @spec date_time_formats(Locale.locale_name() | LanguageTag.t(), calendar) ::
                {:ok, map()} | {:error, {module(), String.t()}}

        def date_time_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, cldr_calendar) do
          date_time_formats(cldr_locale_name, cldr_calendar)
        end

        def date_time_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the available non-standard datetime formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag.t()`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
        The default is `:gregorian`

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_available_formats "en"
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
        @spec date_time_available_formats(Locale.locale_name() | LanguageTag.t(), calendar) ::
                {:ok, formats}
        def date_time_available_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_available_formats(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          date_time_available_formats(cldr_locale_name, calendar)
        end

        def date_time_available_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_available_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the interval formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag.t()`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`

        ## Examples:


        """
        @spec date_time_interval_formats(Locale.locale_name() | LanguageTag.t(), calendar()) ::
                {:ok, formats}
        def date_time_interval_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_interval_formats(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          date_time_interval_formats(cldr_locale_name, calendar)
        end

        def date_time_interval_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_interval_formats(locale, calendar)
          end
        end

        @doc """
        Returns the fallback format for a given
        locale and calendar type

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag.t()`

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_interval_fallback "en", :gregorian
            [0, " – ", 1]

        """
        @spec date_time_interval_fallback(Locale.locale_name() | LanguageTag.t(), calendar()) ::
                list() | {:error, {module(), String.t()}}

        def date_time_interval_fallback(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_interval_fallback(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          date_time_interval_fallback(cldr_locale_name, calendar)
        end

        def date_time_interval_fallback(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_interval_fallback(locale, calendar)
          end
        end

        @doc """
        Returns the positive and negative hour format
        for a timezone offset for a given locale.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        ## Example

            iex> #{inspect(__MODULE__)}.hour_format "en"
            {:ok, {"+HH:mm", "-HH:mm"}}

        """
        @spec hour_format(Locale.locale_name() | LanguageTag.t()) ::
                {:ok, {String.t(), String.t()}}
        def hour_format(locale \\ unquote(backend).get_locale())

        def hour_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          hour_format(cldr_locale_name)
        end

        def hour_format(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            hour_format(locale)
          end
        end

        @doc """
        Returns the GMT offset format list for a
        for a timezone offset for a given locale.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        ## Example

            iex> #{inspect(__MODULE__)}.gmt_format "en"
            {:ok, ["GMT", 0]}

        """
        @spec gmt_format(Locale.locale_name() | LanguageTag.t()) ::
                {:ok, [non_neg_integer | String.t(), ...]}
        def gmt_format(locale \\ unquote(backend).get_locale())

        def gmt_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          gmt_format(cldr_locale_name)
        end

        def gmt_format(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            gmt_format(locale)
          end
        end

        @doc """
        Returns the GMT format string for a
        for a timezone with an offset of zero for
        a given locale.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`

        ## Example

            iex> #{inspect(__MODULE__)}.gmt_zero_format :en
            {:ok, "GMT"}

            iex> #{inspect(__MODULE__)}.gmt_zero_format "fr"
            {:ok, "UTC"}

        """
        @spec gmt_zero_format(Locale.locale_name() | LanguageTag.t()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}
        def gmt_zero_format(locale \\ unquote(backend).get_locale())

        def gmt_zero_format(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          gmt_zero_format(cldr_locale_name)
        end

        def gmt_zero_format(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            gmt_zero_format(locale)
          end
        end

        for locale <- Cldr.Locale.Loader.known_locale_names(config) do
          locale_data = Cldr.Locale.Loader.get_locale(locale, config)
          calendars = Cldr.Config.calendars_for_locale(locale, config)

          def calendars_for(unquote(locale)), do: {:ok, unquote(calendars)}

          def gmt_format(unquote(locale)),
            do: {:ok, unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_format]))}

          def gmt_zero_format(unquote(locale)),
            do: {:ok, unquote(get_in(locale_data, [:dates, :time_zone_names, :gmt_zero_format]))}

          hour_formats =
            locale_data
            |> get_in([:dates, :time_zone_names, :hour_format])
            |> String.split(";")
            |> Elixir.List.to_tuple()

          def hour_format(unquote(locale)), do: {:ok, unquote(hour_formats)}

          for calendar <- calendars do
            calendar_data =
              locale_data
              |> Map.get(:dates)
              |> get_in([:calendars, calendar])

            formats = struct(Cldr.Date.Styles, Map.get(calendar_data, :date_formats))

            def date_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(formats))}
            end

            formats = struct(Cldr.Time.Styles, Map.get(calendar_data, :time_formats))

            def time_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(formats))}
            end

            formats =
              struct(
                Cldr.DateTime.Styles,
                Map.get(calendar_data, :date_time_formats)
                |> Map.take(@standard_formats)
              )

            def date_time_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(formats))}
            end

            formats = get_in(calendar_data, [:date_time_formats, :available_formats])

            def date_time_available_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(formats))}
            end

            formats = get_in(calendar_data, [:date_time_formats, :interval_formats])

            interval_format_fallback =
              get_in(
                calendar_data,
                [:date_time_formats, :interval_formats, :interval_format_fallback]
              )

            formats =
              formats
              |> Map.delete(:interval_format_fallback)
              |> Enum.map(fn {k, v} ->
                split_formats =
                  Enum.map(v, fn {k2, v2} ->
                    interval_formats = Cldr.DateTime.Format.split_interval!(v2)
                    {k2, interval_formats}
                  end)
                  |> Map.new()

                {k, split_formats}
              end)
              |> Map.new()

            def date_time_interval_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(formats))}
            end

            def date_time_interval_fallback(unquote(locale), unquote(calendar)) do
              unquote(interval_format_fallback)
            end
          end

          def date_formats(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}

          def time_formats(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}

          def date_time_formats(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}

          def date_time_available_formats(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}

          def date_time_interval_formats(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}

          def date_time_interval_fallback(unquote(locale), calendar),
            do: {:error, Cldr.Calendar.calendar_error(calendar)}
        end

        def calendars_for(locale), do: {:error, Locale.locale_error(locale)}
        def gmt_format(locale), do: {:error, Locale.locale_error(locale)}
        def gmt_zero_format(locale), do: {:error, Locale.locale_error(locale)}
        def hour_format(locale), do: {:error, Locale.locale_error(locale)}
        def date_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def time_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def date_time_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}

        def date_time_available_formats(locale, _calendar),
          do: {:error, Locale.locale_error(locale)}

        def date_time_interval_formats(locale, _calendar),
          do: {:error, Locale.locale_error(locale)}

        def date_time_interval_fallback(locale, _calendar),
          do: {:error, Locale.locale_error(locale)}

        @doc """
        Returns the time period for a given time of day.

        ## Arguments

        * `time` is any `Time.t` or a map with at least `:hour`,
          `:minute` and `:second` keys

        * `language` is a binary representation of a valid and
          configured language in `Cldr`

        The time period is a locale-specific key that is used
        to localise a time into a textual representation of "am",
        "pm", "noon", "midnight", "evening", "morning" and so on
        as defined in the CLDR day period rules.

        ## Examples

            iex> #{inspect(__MODULE__)}.day_period_for ~T[06:05:54.515228], "en"
            :morning1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[13:05:54.515228], "en"
            :afternoon1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[21:05:54.515228], "en"
            :night1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[21:05:54.515228], "fr"
            :evening1

        """
        @spec day_period_for(:"Elixir.Calendar".time(), LanguageTag.t() | Locale.locale_name()) ::
                atom
        def day_period_for(time, language)

        def day_period_for(time, %LanguageTag{language: language}) do
          day_period_for(time, language)
        end

        @doc """
        Returns a boolean indicating is a given language defines the
        notion of "noon" and "midnight"

        ## Arguments

        * `language` is a binary representation of a valid and
          configured language in `Cldr`

        ## Examples

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? "fr"
            true

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? "en"
            true

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? "af"
            false

        """
        @spec language_has_noon_and_midnight?(LanguageTag.t() | Locale.locale_name()) :: boolean
        def language_has_noon_and_midnight?(locale)

        def language_has_noon_and_midnight?(%LanguageTag{language: language}) do
          language_has_noon_and_midnight?(language)
        end

        # Insert generated functions that will identify which time period key
        # is appropriate for a given time value.  Note that we sort the time
        # periods such that the "at" periods come before the "from"/"before"
        # periods so that the functions are defined in the right order.
        for {language, periods} <- Cldr.Config.day_period_info() do
          for {period, times} <- Enum.sort(periods, fn {_k, v}, _p2 -> !!Map.get(v, "at") end) do
            case times do
              %{"at" => [h, m]} ->
                def day_period_for(%{hour: unquote(h), minute: unquote(m)}, unquote(language)) do
                  unquote(String.to_atom(period))
                end

              # For when the time range wraps around midnight
              %{"from" => [h1, 0], "before" => [h2, 0]} when h2 < h1 ->
                def day_period_for(%{hour: hour}, unquote(language))
                    when rem(hour, 24) >= unquote(h1) or rem(hour, 24) < unquote(h2) do
                  unquote(String.to_atom(period))
                end

              # For when the time range does not wrap around midnight
              %{"from" => [h1, 0], "before" => [h2, 0]} ->
                def day_period_for(%{hour: hour}, unquote(language))
                    when rem(hour, 24) >= unquote(h1) and rem(hour, 24) < unquote(h2) do
                  unquote(String.to_atom(period))
                end
            end
          end

          # We also need a way to find out of a language supports the
          # concept of "noon" and "midnight"
          if Map.get(periods, "noon") && Map.get(periods, "midnight") do
            def language_has_noon_and_midnight?(unquote(language)), do: true
          end
        end

        def language_has_noon_and_midnight?(locale_name) when is_atom(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            language_has_noon_and_midnight?(locale.language)
          end
        end

        def day_period_for(time, locale_name) when is_atom(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            day_period_for(time, locale.language)
          end
        end

        def day_period_for(time, locale) do
          {:error, Locale.locale_error(locale)}
        end

        def language_has_noon_and_midnight?(_), do: false
      end
    end
  end
end
