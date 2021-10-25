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
          with {:ok, locale} <- Cldr.validate_locale(locale_name, unquote(backend)) do
            get_locale(locale)
          end
        end

        @doc """
        Returns a `{:ok, string}` representing a relative time (ago, in) for a given
        number, Date or Datetime.  Returns `{:error, reason}` when errors are detected.

        * `relative` is a number or Date/Datetime representing the time distance from `now` or from
          options[:relative_to]

        * `options` is a `Keyword` list of options which are:

        ## Options

        * `:locale` is the locale in which the binary is formatted.
          The default is `Cldr.get_locale/0`

        * `:style` is the style of the binary.  Style may be `:default`, `:narrow` or `:short`

        * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
          `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
          `:sun`, `:quarter`

        * `:relative_to` is the baseline Date or Datetime from which the difference from `relative` is
          calculated when `relative` is a Date or a DateTime. The default for a Date is `Date.utc_today`,
          for a DateTime it is `DateTime.utc_now`

        ### Notes

        When `options[:unit]` is not specified, `MyApp.Cldr.DateTime.Relative.to_string/2`
        attempts to identify the appropriate unit based upon the magnitude of `relative`.
        For example, given a parameter of less than `60`, then `to_string/2` will
        assume `:seconds` as the unit.  See `unit_from_relative_time/1`.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string(-1)
            {:ok, "1 second ago"}

            iex> #{inspect(__MODULE__)}.to_string(1)
            {:ok, "in 1 second"}

            iex> #{inspect(__MODULE__)}.to_string(1, unit: :day)
            {:ok, "tomorrow"}

            iex> #{inspect(__MODULE__)}.to_string(1, unit: :day, locale: "fr")
            {:ok, "demain"}

            iex> #{inspect(__MODULE__)}.to_string(1, unit: :day, style: :narrow)
            {:ok, "tomorrow"}

            iex> #{inspect(__MODULE__)}.to_string(1234, unit: :year)
            {:ok, "in 1,234 years"}

            iex> #{inspect(__MODULE__)}.to_string(1234, unit: :year, locale: "fr")
            {:ok, "dans 1 234 ans"}

            iex> #{inspect(__MODULE__)}.to_string(31)
            {:ok, "in 31 seconds"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-04-29], relative_to: ~D[2017-04-26])
            {:ok, "in 3 days"}

            iex> #{inspect(__MODULE__)}.to_string(310, style: :short, locale: "fr")
            {:ok, "dans 5 min"}

            iex> #{inspect(__MODULE__)}.to_string(310, style: :narrow, locale: "fr")
            {:ok, "+5 min"}

            iex> #{inspect(__MODULE__)}.to_string 2, unit: :wed, style: :short, locale: "en"
            {:ok, "in 2 Wed."}

            iex> #{inspect(__MODULE__)}.to_string 1, unit: :wed, style: :short
            {:ok, "next Wed."}

            iex> #{inspect(__MODULE__)}.to_string -1, unit: :wed, style: :short
            {:ok, "last Wed."}

            iex> #{inspect(__MODULE__)}.to_string -1, unit: :wed
            {:ok, "last Wednesday"}

            iex> #{inspect(__MODULE__)}.to_string -1, unit: :quarter
            {:ok, "last quarter"}

            iex> #{inspect(__MODULE__)}.to_string -1, unit: :mon, locale: "fr"
            {:ok, "lundi dernier"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-04-29], unit: :ziggeraut)
            {:error, {Cldr.UnknownTimeUnit,
             "Unknown time unit :ziggeraut.  Valid time units are [:day, :hour, :minute, :month, :second, :week, :year, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :quarter]"}}

        """

        @spec to_string(number | map(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(time, options \\ []) do
          Cldr.DateTime.Relative.to_string(time, unquote(backend), options)
        end

        @doc """
        Returns a `{:ok, string}` representing a relative time (ago, in) for a given
        number, Date or Datetime or raises an exception on error.

        ## Arguments

        * `relative` is a number or Date/Datetime representing the time distance from `now` or from
          options[:relative_to].

        * `options` is a `Keyword` list of options.

        ## Options

        * `:locale` is the locale in which the binary is formatted.
          The default is `Cldr.get_locale/0`

        * `:style` is the format of the binary.  Style may be `:default`, `:narrow` or `:short`.
          The default is `:default`

        * `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
          `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
          `:sun`, `:quarter`

        * `:relative_to` is the baseline Date or Datetime from which the difference from `relative` is
          calculated when `relative` is a Date or a DateTime. The default for a Date is `Date.utc_today`,
          for a DateTime it is `DateTime.utc_now`

        See `to_string/2`

        """
        @spec to_string!(number | map(), Keyword.t()) :: String.t()
        def to_string!(time, options \\ []) do
          Cldr.DateTime.Relative.to_string!(time, unquote(backend), options)
        end

        for locale_name <- Cldr.Locale.Loader.known_locale_names(config) do
          locale_data =
            locale_name
            |> Cldr.Locale.Loader.get_locale(config)
            |> Map.get(:date_fields)
            |> Map.take(@unit_keys)

          def get_locale(%LanguageTag{cldr_locale_name: unquote(locale_name)}),
            do: unquote(Macro.escape(locale_data))
        end
      end
    end
  end
end
