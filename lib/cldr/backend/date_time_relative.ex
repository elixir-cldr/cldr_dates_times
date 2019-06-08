defmodule Cldr.DateTime.Relative.Backend do
  @moduledoc false

  def define_date_time_relative_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule DateTime.Relative do
        @second 1
        @minute 60
        @hour 3600
        @day 86400
        @week 604_800
        @month 2_629_743.83
        @year 31_556_926

        @unit %{
          second: @second,
          minute: @minute,
          hour: @hour,
          day: @day,
          week: @week,
          month: @month,
          year: @year
        }

        @other_units [:mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]
        @unit_keys Map.keys(@unit) ++ @other_units

        @doc false
        def get_locale(locale \\ unquote(backend).get_locale())

        def get_locale(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale) do
            get_locale(locale)
          end
        end

        for locale_name <- Cldr.Config.known_locale_names(config) do
          locale_data =
            locale_name
            |> Cldr.Config.get_locale(config)
            |> Map.get(:date_fields)
            |> Map.take(@unit_keys)

          def get_locale(%LanguageTag{cldr_locale_name: unquote(locale_name)}),
            do: unquote(Macro.escape(locale_data))
        end
      end
    end
  end
end
