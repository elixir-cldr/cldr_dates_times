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

        @date_symbols [
          "Y",
          "y",
          "G",
          "M",
          "L",
          "D",
          "d",
          "U",
          "u",
          "Q",
          "q",
          "F",
          "g",
          "W",
          "w",
          "E",
          "e",
          "c"
        ]

        @time_symbols [
          "H",
          "h",
          "K",
          "k",
          "C",
          "m",
          "s",
          "S",
          "A",
          "Z",
          "z",
          "V",
          "v",
          "X",
          "x",
          "O"
        ]

        @doc "A struct from a format id as an atom to a format string"
        @type formats :: map()

        @doc "The CLDR calendar type as an atom"
        @type calendar :: atom()

        @doc """
        Returns a list of calendars defined for a given locale.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        ## Example

            iex> #{inspect(__MODULE__)}.calendars_for(:en)
            {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
             :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
             :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]}

        """
        @spec calendars_for(Locale.locale_reference()) ::
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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_formats(:en)
            {:ok, %Cldr.Date.Formats{
              full: "EEEE, MMMM d, y",
              long: "MMMM d, y",
              medium: "MMM d, y",
              short: "M/d/yy"
            }}

            iex> #{inspect(__MODULE__)}.date_formats(:en, :buddhist)
            {:ok, %Cldr.Date.Formats{
              full: "EEEE, MMMM d, y G",
              long: "MMMM d, y G",
              medium: "MMM d, y G",
              short: "M/d/y GGGGG"
            }}

        """
        @spec date_formats(Locale.locale_reference(), calendar) ::
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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.time_formats(:en)
            {:ok, %Cldr.Time.Formats{
              full: "h:mm:ss a zzzz",
              long: "h:mm:ss a z",
              medium: "h:mm:ss a",
              short: "h:mm a"
            }}

            iex> #{inspect(__MODULE__)}.time_formats(:en, :buddhist)
            {:ok, %Cldr.Time.Formats{
              full: "h:mm:ss a zzzz",
              long: "h:mm:ss a z",
              medium: "h:mm:ss a",
              short: "h:mm a"
            }}

        """
        @spec time_formats(Locale.locale_reference(), calendar) ::
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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_formats(:en)
            {:ok, %Cldr.DateTime.Formats{
              full: "{1}, {0}",
              long: "{1}, {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"
            }}

            iex> #{inspect(__MODULE__)}.date_time_formats(:en, :buddhist)
            {:ok, %Cldr.DateTime.Formats{
              full: "{1}, {0}",
              long: "{1}, {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"
            }}

        """
        @spec date_time_formats(Locale.locale_reference(), calendar) ::
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
        Returns a map of the standard datetime "at" formats for a given
        locale and calendar.

        An "at" format is one where the datetime is formatted with the
        date part separated from the time part by a localized version
        of "at".

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`,

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_at_formats(:en)
            {:ok, %Cldr.DateTime.Formats{
              full: "{1} 'at' {0}",
              long: "{1} 'at' {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"}
            }

            iex> #{inspect(__MODULE__)}.date_time_at_formats(:en, :buddhist)
            {:ok, %Cldr.DateTime.Formats{
              full: "{1} 'at' {0}",
              long: "{1} 'at' {0}",
              medium: "{1}, {0}",
              short: "{1}, {0}"}
            }

        """
        @spec date_time_at_formats(Locale.locale_reference(), calendar) ::
                {:ok, map()} | {:error, {module(), String.t()}}

        def date_time_at_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_at_formats(%LanguageTag{cldr_locale_name: cldr_locale_name}, cldr_calendar) do
          date_time_at_formats(cldr_locale_name, cldr_calendar)
        end

        def date_time_at_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_at_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the available datetime formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_available_formats "en"
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
        @spec date_time_available_formats(Locale.locale_reference(), calendar) ::
            {:ok, formats} | {:error, {module, String.t()}}

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
        Returns a map of the available date formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_available_formats "en"

        """
        @spec date_available_formats(Locale.locale_reference(), calendar) ::
            {:ok, formats} | {:error, {module, String.t()}}

        def date_available_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_available_formats(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          date_available_formats(cldr_locale_name, calendar)
        end

        def date_available_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_available_formats(locale, calendar)
          end
        end

        @doc """
        Returns a map of the available time formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.time_available_formats :en

        """
        @spec time_available_formats(Locale.locale_reference(), calendar) ::
            {:ok, formats} | {:error, {module, String.t()}}

        def time_available_formats(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def time_available_formats(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          time_available_formats(cldr_locale_name, calendar)
        end

        def time_available_formats(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            time_available_formats(locale, calendar)
          end
        end

        @doc false
        def date_time_available_format_tokens(
              locale \\ unquote(backend).get_locale(),
              calendar \\ Cldr.Calendar.default_cldr_calendar()
            )

        def date_time_available_format_tokens(
              %LanguageTag{cldr_locale_name: cldr_locale_name},
              calendar
            ) do
          date_time_available_format_tokens(cldr_locale_name, calendar)
        end

        def date_time_available_format_tokens(locale_name, calendar) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            date_time_available_format_tokens(locale, calendar)
          end
        end

        @doc """
        Returns a map of the interval formats for a
        given locale and calendar.

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_interval_formats(:en, :gregorian)
            {:ok,
             %{
               h: %{a: ["h a – ", "h a"], h: ["h – ", "h a"]},
               d: %{d: ["d – ", "d"]},
               y: %{y: ["y – ", "y"]},
               M: %{M: ["M – ", "M"]},
               Bh: %{h: ["h – ", "h B"], B: ["h B – ", "h B"]},
               Bhm: %{
                 m: ["h:mm – ", "h:mm B"],
                 h: ["h:mm – ", "h:mm B"],
                 B: ["h:mm B – ", "h:mm B"]
               },
               Gy: %{y: ["y – ", "y G"], G: ["y G – ", "y G"]},
               GyMMM: %{
                 y: ["MMM y – ", "MMM y G"],
                 M: ["MMM – ", "MMM y G"],
                 G: ["MMM y G – ", "MMM y G"]
               },
               GyMMMEd: %{
                 d: ["E, MMM d – ", "E, MMM d, y G"],
                 y: ["E, MMM d, y – ", "E, MMM d, y G"],
                 M: ["E, MMM d – ", "E, MMM d, y G"],
                 G: ["E, MMM d, y G – ", "E, MMM d, y G"]
               },
               GyMMMd: %{
                 d: ["MMM d – ", "d, y G"],
                 y: ["MMM d, y – ", "MMM d, y G"],
                 M: ["MMM d – ", "MMM d, y G"],
                 G: ["MMM d, y G – ", "MMM d, y G"]
               },
               GyMd: %{
                 d: ["M/d/y – ", "M/d/y G"],
                 y: ["M/d/y – ", "M/d/y G"],
                 M: ["M/d/y – ", "M/d/y G"],
                 G: ["M/d/y G – ", "M/d/y G"]
               },
               H: %{H: ["HH – ", "HH"]},
               Hm: %{m: ["HH:mm – ", "HH:mm"], H: ["HH:mm – ", "HH:mm"]},
               Hmv: %{m: ["HH:mm – ", "HH:mm v"], H: ["HH:mm – ", "HH:mm v"]},
               MEd: %{d: ["E, M/d – ", "E, M/d"], M: ["E, M/d – ", "E, M/d"]},
               MMM: %{M: ["MMM – ", "MMM"]},
               MMMEd: %{
                 d: ["E, MMM d – ", "E, MMM d"],
                 M: ["E, MMM d – ", "E, MMM d"]
               },
               MMMd: %{d: ["MMM d – ", "d"], M: ["MMM d – ", "MMM d"]},
               Md: %{d: ["M/d – ", "M/d"], M: ["M/d – ", "M/d"]},
               hm: %{
                 m: ["h:mm – ", "h:mm a"],
                 a: ["h:mm a – ", "h:mm a"],
                 h: ["h:mm – ", "h:mm a"]
               },
               hmv: %{
                 m: ["h:mm – ", "h:mm a v"],
                 a: ["h:mm a – ", "h:mm a v"],
                 h: ["h:mm – ", "h:mm a v"]
               },
               yM: %{y: ["M/y – ", "M/y"], M: ["M/y – ", "M/y"]},
               yMEd: %{
                 d: ["E, M/d/y – ", "E, M/d/y"],
                 y: ["E, M/d/y – ", "E, M/d/y"],
                 M: ["E, M/d/y – ", "E, M/d/y"]
               },
               yMMM: %{y: ["MMM y – ", "MMM y"], M: ["MMM – ", "MMM y"]},
               yMMMEd: %{
                 d: ["E, MMM d – ", "E, MMM d, y"],
                 y: ["E, MMM d, y – ", "E, MMM d, y"],
                 M: ["E, MMM d – ", "E, MMM d, y"]
               },
               yMMMM: %{y: ["MMMM y – ", "MMMM y"], M: ["MMMM – ", "MMMM y"]},
               yMMMd: %{
                 d: ["MMM d – ", "d, y"],
                 y: ["MMM d, y – ", "MMM d, y"],
                 M: ["MMM d – ", "MMM d, y"]
               },
               yMd: %{
                 d: ["M/d/y – ", "M/d/y"],
                 y: ["M/d/y – ", "M/d/y"],
                 M: ["M/d/y – ", "M/d/y"]
               },
               GyM: %{
                 y: ["M/y – ", "M/y G"],
                 M: ["M/y – ", "M/y G"],
                 G: ["M/y G – ", "M/y G"]
               },
               GyMEd: %{
                 d: ["E, M/d/y – ", "E, M/d/y G"],
                 y: ["E, M/d/y – ", "E, M/d/y G"],
                 M: ["E, M/d/y – ", "E, M/d/y G"],
                 G: ["E, M/d/y G – ", "E, M/d/y G"]
               },
               Hv: %{H: ["HH – ", "HH v"]},
               hv: %{a: ["h a – ", "h a v"], h: ["h – ", "h a v"]}
             }}

        """
        @spec date_time_interval_formats(Locale.locale_reference(), calendar()) ::
                {:ok, formats} | {:error, {module, String.t()}}

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
        Returns a list of the date_time format IDs that are
        available in all known locales.

        The format IDs returned by `common_date_time_format_names/0`
        are guaranteed to be available in all known locales,

        ## Example:

            iex> #{inspect(__MODULE__)}.common_date_time_format_names()
            [:Bh, :Bhm, :Bhms, :E, :EBhm, :EBhms, :EHm, :EHms, :Ed, :Ehm, :Ehms, :Gy,
             :GyMMM, :GyMMMEd, :GyMMMd, :GyMd, :H, :Hm, :Hms, :Hmsv, :Hmv, :M, :MEd, :MMM,
             :MMMEd, :MMMMW, :MMMMd, :MMMd, :Md, :d, :h, :hm, :hms, :hmsv, :hmv, :ms, :y,
             :yM, :yMEd, :yMMM, :yMMMEd, :yMMMM, :yMMMd, :yMd, :yQQQ, :yQQQQ, :yw]

        """
        @spec common_date_time_format_names() :: [Format.format_id()]
        def common_date_time_format_names do
          Cldr.DateTime.Format.common_date_time_format_names(unquote(backend))
        end

        @doc """
        Returns the fallback format for a given
        locale and calendar type

        ## Arguments

        * `locale` is any locale returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        * `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
          The default is `:gregorian`.

        ## Examples:

            iex> #{inspect(__MODULE__)}.date_time_interval_fallback(:en, :gregorian)
            [0, " – ", 1]

        """
        @spec date_time_interval_fallback(Locale.locale_reference(), calendar()) ::
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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        ## Example

            iex> #{inspect(__MODULE__)}.hour_format("en")
            {:ok, {"+HH:mm", "-HH:mm"}}

        """
        @spec hour_format(Locale.locale_reference()) ::
            {:ok, {String.t(), String.t()}} | {:error, {module, String.t()}}

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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        ## Example

            iex> #{inspect(__MODULE__)}.gmt_format(:en)
            {:ok, ["GMT", 0]}

        """
        @spec gmt_format(Locale.locale_reference()) ::
            {:ok, [non_neg_integer | String.t(), ...]} | {:error, {module, String.t()}}

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
          or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

        ## Example

            iex> #{inspect(__MODULE__)}.gmt_zero_format(:en)
            {:ok, "GMT"}

            iex> #{inspect(__MODULE__)}.gmt_zero_format(:fr)
            {:ok, "UTC"}

        """
        @spec gmt_zero_format(Locale.locale_reference()) ::
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

            date_formats = struct(Cldr.Date.Formats, Map.get(calendar_data, :date_formats))

            def date_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(date_formats))}
            end

            time_formats = struct(Cldr.Time.Formats, Map.get(calendar_data, :time_formats))

            def time_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(time_formats))}
            end

            date_time_formats =
              struct(
                Cldr.DateTime.Formats,
                Map.get(calendar_data, :date_time_formats)
                |> Map.take(@standard_formats)
              )

            def date_time_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(date_time_formats))}
            end

            date_time_at_formats =
              struct(
                Cldr.DateTime.Formats,
                Map.get(calendar_data, :date_time_formats_at_time)
                |> Map.get(:standard)
                |> Map.take(@standard_formats)
              )

            def date_time_at_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(date_time_at_formats))}
            end

            # For available formats we need to check for formats that have
            # pluralization rules. For those rules we capture the field that
            # is pluralizad at runtime - its the last token in the tokenized
            # name of the format.

            available_formats =
              calendar_data
              |> get_in([:date_time_formats, :available_formats])
              |> Enum.map(fn
                {name, %{other: _other} = plurals} ->
                  {:ok, tokens, _} = Cldr.DateTime.Format.Compiler.tokenize(to_string(name))
                  [{pluralize, _, _} | _rest] = Enum.reverse(tokens)
                  {name, Map.put(plurals, :pluralize, pluralize)}

                other ->
                  other
              end)
              |> Map.new()

            def date_time_available_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(available_formats))}
            end

            date_available_formats =
              Enum.filter(available_formats, fn {format_id, _} ->
                remaining =
                  format_id
                  |> to_string()
                  |> String.replace(@date_symbols, "")

                remaining == ""
              end)
              |> Map.new()

            def date_available_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(date_available_formats))}
            end

            time_available_formats =
              Enum.filter(available_formats, fn {format_id, _} ->
                remaining =
                  format_id
                  |> to_string()
                  |> String.replace(@time_symbols, "")

                remaining == ""
              end)
              |> Map.new()

            def time_available_formats(unquote(locale), unquote(calendar)) do
              {:ok, unquote(Macro.escape(time_available_formats))}
            end

            available_format_tokens =
              Enum.map(available_formats, fn {format_id, format} ->
                {:ok, tokens} = Cldr.DateTime.Format.Compiler.tokenize_skeleton(format_id)
                {format_id, tokens}
              end)
              |> Map.new()

            def date_time_available_format_tokens(unquote(locale), unquote(calendar)) do
              unquote(Macro.escape(available_format_tokens))
            end

            interval_formats =
              get_in(calendar_data, [:date_time_formats, :interval_formats])

            interval_format_fallback =
              get_in(
                calendar_data,
                [:date_time_formats, :interval_formats, :interval_format_fallback]
              )

            interval_formats =
              interval_formats
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
              {:ok, unquote(Macro.escape(interval_formats))}
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

          def date_time_at_formats(unquote(locale), calendar),
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
        def date_time_at_formats(locale, _calendar), do: {:error, Locale.locale_error(locale)}

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

            iex> #{inspect(__MODULE__)}.day_period_for ~T[06:05:54.515228], :en
            :morning1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[13:05:54.515228], :en
            :afternoon1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[21:05:54.515228], :en
            :night1

            iex> #{inspect(__MODULE__)}.day_period_for ~T[21:05:54.515228], :fr
            :evening1

        """
        @spec day_period_for(
                Elixir.Calendar.time(),
                LanguageTag.t() | String.t() | Locale.locale_name()
              ) ::
                atom | {:error, {module, String.t()}}

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

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? :fr
            true

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? :en
            true

            iex> #{inspect(__MODULE__)}.language_has_noon_and_midnight? :af
            false

        """
        @spec language_has_noon_and_midnight?(LanguageTag.t() | String.t() | Locale.locale_name()) ::
                boolean | {:error, {module, String.t()}}

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
