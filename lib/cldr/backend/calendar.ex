defmodule Cldr.Calendar.Backend do
  @moduledoc false

  def define_calendar_module(config) do
    backend = config.backend

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule Calendar do
        @moduledoc """
        Calendar support functions for formatting dates, times and datetimes.

        `Cldr` defines formats for several calendars, the names of which
        are returned by `Cldr.Calendar.known_calendars/0`.

        Currently this implementation only supports the `:gregorian`
        calendar which aligns with the proleptic Gregorian calendar
        defined by Elixir, `Calendar.ISO`.

        This module will be extacted in the future to become part of
        a separate calendrical module.
        """

        alias Cldr.Locale

        @doc false
        def era(locale \\ unquote(backend).get_locale(), calendar \\ @default_calendar)

        def era(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          era(cldr_locale_name, calendar)
        end

        @doc false
        def period(locale \\ unquote(backend).get_locale(), calendar \\ @default_calendar)

        def period(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          period(cldr_locale_name, calendar)
        end

        @doc false
        def quarter(locale \\ unquote(backend).get_locale(), calendar \\ @default_calendar)

        def quarter(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          quarter(cldr_locale_name, calendar)
        end

        @doc false
        def month(locale \\ unquote(backend).get_locale(), calendar \\ @default_calendar)

        def month(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          month(cldr_locale_name, calendar)
        end

        @doc false
        def day(locale \\ unquote(backend).get_locale(), calendar \\ @default_calendar)

        def day(%LanguageTag{cldr_locale_name: cldr_locale_name}, calendar) do
          day(cldr_locale_name, calendar)
        end

        for locale_name <- Cldr.Config.known_locale_names(config) do
          date_data =
            locale_name
            |> Cldr.Config.get_locale(config)
            |> Map.get(:dates)

          calendars =
            date_data
            |> Map.get(:calendars)
            |> Map.take(Cldr.known_calendars())
            |> Map.keys()

          for calendar <- calendars do
            def era(unquote(locale_name), unquote(calendar)) do
              unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :eras])))
            end

            def period(unquote(locale_name), unquote(calendar)) do
              unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :day_periods])))
            end

            def quarter(unquote(locale_name), unquote(calendar)) do
              unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :quarters])))
            end

            def month(unquote(locale_name), unquote(calendar)) do
              unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :months])))
            end

            def day(unquote(locale_name), unquote(calendar)) do
              unquote(Macro.escape(get_in(date_data, [:calendars, calendar, :days])))
            end
          end

          def era(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
          def period(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
          def quarter(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
          def month(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
          def day(unquote(locale_name), calendar), do: {:error, calendar_error(calendar)}
        end

        def era(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def period(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def quarter(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def month(locale, _calendar), do: {:error, Locale.locale_error(locale)}
        def day(locale, _calendar), do: {:error, Locale.locale_error(locale)}
      end
    end
  end
end