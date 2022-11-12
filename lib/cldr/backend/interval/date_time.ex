defmodule Cldr.DateTime.Interval.Backend do
  @moduledoc false

  def define_date_time_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule DateTime.Interval do
        @moduledoc """
        Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
        shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
        to take a start and end date, time or datetime plus a formatting pattern
        and use that information to produce a localized format.

        See `Cldr.Interval.to_string/3` and `Cldr.DateTime.Interval.to_string/3`

        """

        naivedatetime = quote do
          %{
            year: _,
            month: _,
            day: _,
            hour: _,
            minute: _,
            second: _,
            microsecond: _,
            calendar: var!(calendar, unquote(__MODULE__))
          }
        end

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          @doc false
          def to_string(%CalendarInterval{} = interval) do
            locale = unquote(backend).get_locale
            Cldr.DateTime.Interval.to_string(interval, unquote(backend), locale: locale)
          end

          @doc """
          Returns a `CalendarInterval` as a localised
          datetime string.

          ## Arguments

          * `range` is a `CalendarInterval.t`

          * `options` is a keyword list of options. The default is `[]`.

          ## Options

          * `:format` is one of `:short`, `:medium` or `:long` or a
            specific format type or a string representing of an interval
            format. The default is `:medium`.

          * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

          * `:number_system` a number system into which the formatted datetime
             digits should be transliterated

          ## Returns

          * `{:ok, string}` or

          * `{:error, {exception, reason}}`

          ## Notes

          * `CalendarInterval` support requires adding the
            dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
            to the `deps` configuration in `mix.exs`.

          * For more information on interval format string
            see the `Cldr.Interval`.

          * The available predefined formats that can be applied are the
            keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
            where `"en"` can be replaced by any configuration locale name and `:gregorian`
            is the underlying CLDR calendar type.

          * In the case where `from` and `to` are equal, a single
            date is formatted instead of an interval

          ## Examples

              iex> use CalendarInterval
              iex> #{inspect(__MODULE__)}.to_string ~I"2020-01-01 00:00/10:00"
              {:ok, "Jan 1, 2020, 12:00:00 AM – 10:00:00 AM"}

          """

          @spec to_string(CalendarInterval.t(), Keyword.t()) ::
                  {:ok, String.t()} | {:error, {module, String.t()}}

          def to_string(%CalendarInterval{} = interval, options) do
            locale = unquote(backend).get_locale
            options = Keyword.put_new(options, :locale, locale)
            Cldr.DateTime.Interval.to_string(interval, unquote(backend), options)
          end
        end

        @doc """
        Returns a string representing the formatted
        interval formed by two dates.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.datetime` type.

        * `to` is any map that conforms to the
          `Calendar.datetime` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone datetime.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        ## Returns

        * `{:ok, string}` or

        * `{:error, {exception, reason}}`

        ## Notes

        * `CalendarInterval` support requires adding the
          dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
          to the `deps` configuration in `mix.exs`.

        * For more information on interval format string
          see the `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configuration locale name and `:gregorian`
          is the underlying CLDR calendar type.

        * In the case where `from` and `to` are equal, a single
          date is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z],
            ...> ~U[2020-12-31 10:00:00.0Z]
            {:ok, "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"}

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z], nil
            {:ok, "Jan 1, 2020, 12:00:00 AM –"}

        """
        @spec to_string(
                  Elixir.Calendar.naive_datetime() | nil,
                  Elixir.Calendar.naive_datetime() | nil, Keyword.t()
              ) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(from, to, options \\ [])

        def to_string(unquote(naivedatetime) = from, unquote(naivedatetime) = to, options) do
          do_to_string(from, to, options)
        end

        def to_string(nil = from, unquote(naivedatetime) = to, options) do
          do_to_string(from, to, options)
        end

        def to_string(unquote(naivedatetime) = from, nil = to, options) do
          do_to_string(from, to, options)
        end

        def do_to_string(from, to, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.DateTime.Interval.to_string(from, to, unquote(backend), options)
        end

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          @doc false
          def to_string!(%CalendarInterval{} = interval) do
            locale = unquote(backend).get_locale
            Cldr.DateTime.Interval.to_string!(interval, unquote(backend), locale: locale)
          end

          @doc """
          Returns a `CalendarInterval` as a localised
          datetime string or raises an exception.

          ## Arguments

          * `range` is a `CalendarInterval.t`

          * `options` is a keyword list of options. The default is `[]`.

          ## Options

          * `:format` is one of `:short`, `:medium` or `:long` or a
            specific format type or a string representing of an interval
            format. The default is `:medium`.

          * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

          * `:number_system` a number system into which the formatted datetime
             digits should be transliterated

          ## Returns

          * `string` or

          * raises an exception

          ## Notes

          * `CalendarInterval` support requires adding the
            dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
            to the `deps` configuration in `mix.exs`.

          * For more information on interval format string
            see the `Cldr.Interval`.

          * The available predefined formats that can be applied are the
            keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
            where `"en"` can be replaced by any configuration locale name and `:gregorian`
            is the underlying CLDR calendar type.

          * In the case where `from` and `to` are equal, a single
            date is formatted instead of an interval

          ## Examples

              iex> use CalendarInterval
              iex> #{inspect(__MODULE__)}.to_string! ~I"2020-01-01 00:00/10:00"
              "Jan 1, 2020, 12:00:00 AM – 10:00:59 AM"

          """

          @spec to_string!(CalendarInterval.t(), Keyword.t()) ::
                  String.t() | no_return

          def to_string!(%CalendarInterval{} = interval, options) do
            locale = unquote(backend).get_locale
            options = Keyword.put_new(options, :locale, locale)
            Cldr.DateTime.Interval.to_string!(interval, unquote(backend), options)
          end
        end

        @doc """
        Returns a string representing the formatted
        interval formed by two dates or raises an
        exception.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.datetime` type.

        * `to` is any map that conforms to the
          `Calendar.datetime` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone datetime.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`.

        * `number_system:` a number system into which the formatted date digits should
          be transliterated.

        ## Returns

        * `string` or

        * raises an exception

        ## Notes

        * For more information on interval format string
          see the `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configuration locale name and `:gregorian`
          is the underlying CLDR calendar type.

        * In the case where `from` and `to` are equal, a single
          date is formatted instead of an interval.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! ~U[2020-01-01 00:00:00.0Z],
            ...> ~U[2020-12-31 10:00:00.0Z]
            "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"

        """
        @spec to_string!(
                Elixir.Calendar.naive_datetime() | nil,
                Elixir.Calendar.naive_datetime() | nil,
                Keyword.t()
              ) ::
                String.t() | no_return()

        def to_string!(from, to, options \\ [])

        def to_string!(unquote(naivedatetime) = from, unquote(naivedatetime) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(nil = from, unquote(naivedatetime) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(unquote(naivedatetime) = from, nil = to, options) do
          do_to_string!(from, to, options)
        end

        def do_to_string!(from, to, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.DateTime.Interval.to_string!(from, to, unquote(backend), options)
        end
      end
    end
  end
end
