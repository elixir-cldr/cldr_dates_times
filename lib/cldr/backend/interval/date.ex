defmodule Cldr.Date.Interval.Backend do
  @moduledoc false

  def define_date_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule Date.Interval do
        @moduledoc """
        Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
        shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
        to take a start and end date, time or datetime plus a formatting pattern
        and use that information to produce a localized format.

        See `#{inspect(__MODULE__)}.to_string/3` and `#{inspect(backend)}.Interval.to_string/3`

        """

        date = quote do
          %{
            year: _,
            month: _,
            day: _,
            calendar: var!(calendar, unquote(__MODULE__))
          }
        end

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          @doc false
          def to_string(%CalendarInterval{} = interval) do
            Cldr.Date.Interval.to_string(interval, unquote(backend), [])
          end
        end

        @doc false
        def to_string(%Elixir.Date.Range{} = interval) do
          Cldr.Date.Interval.to_string(interval, unquote(backend), [])
        end

        @doc """
        Returns a `Date.Range` or `CalendarInterval` as
        a localised string.

        ## Arguments

        * `range` is either a `Date.Range.t` returned from `Date.range/2`
          or a `CalendarInterval.t`

        * `options` is a keyword list of options. The default is `[]`.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:date`, `:month_and_day`, `:month`
          and `:year_and_month`. The default is `:date`.

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `:number_system` a number system into which the formatted date digits should
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

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-12-31])
            {:ok, "Jan 1 – Dec 31, 2020"}

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-01-12])
            {:ok, "Jan 1 – 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long
            {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-12-01]),
            ...> format: :long, style: :year_and_month
            {:ok, "January – December 2020"}

            iex> use CalendarInterval
            iex> #{inspect(__MODULE__)}.to_string ~I"2020-01/12"
            {:ok, "Jan 1 – Dec 31, 2020"}

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :short
            {:ok, "1/1/2020 – 1/12/2020"}

            iex> #{inspect(__MODULE__)}.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long, locale: "fr"
            {:ok, "mer. 1 – dim. 12 janv. 2020"}

        """
        @spec to_string(Cldr.Interval.range(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          def to_string(%CalendarInterval{} = interval, options) do
            Cldr.Date.Interval.to_string(interval, unquote(backend), options)
          end
        end

        def to_string(%Elixir.Date.Range{} = interval, options) do
          Cldr.Date.Interval.to_string(interval, unquote(backend), options)
        end

        @doc false
        def to_string(unquote(date) = from, unquote(date) = to) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), [])
        end

        def to_string(nil = from, unquote(date) = to) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), [])
        end

        def to_string(unquote(date) = from, nil = to) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), [])
        end

        @doc """
        Returns a interval formed from two dates as
        a localised string.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.date` type.

        * `to` is any map that conforms to the
          `Calendar.date` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone date.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:date`, `:month_and_day`, `:month`
          and `:year_and_month`. The default is `:date`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        ## Returns

        * `{:ok, string}` or

        * `{:error, {exception, reason}}`

        ## Notes

        * For more information on interval format string
          see the `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configuration locale name and `:gregorian`
          is the underlying CLDR calendar type.

        * In the case where `from` and `to` are equal, a single
          date is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-12-31]
            {:ok, "Jan 1 – Dec 31, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12]
            {:ok, "Jan 1 – 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12],
            ...> format: :long
            {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-12-01],
            ...> format: :long, style: :year_and_month
            {:ok, "January – December 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12],
            ...> format: :short
            {:ok, "1/1/2020 – 1/12/2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12],
            ...> format: :long, locale: "fr"
            {:ok, "mer. 1 – dim. 12 janv. 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12],
            ...> format: :long, locale: "th", number_system: :thai
            {:ok, "พ. ๑ ม.ค. – อา. ๑๒ ม.ค. ๒๐๒๐"}

        """
        @spec to_string(Elixir.Calendar.date() | nil, Elixir.Calendar.date() | nil, Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(unquote(date) = from, unquote(date) = to, options) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), options)
        end

        def to_string(nil = from, unquote(date) = to, options) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), options)
        end

        def to_string(unquote(date) = from, nil = to, options) do
          Cldr.Date.Interval.to_string(from, to, unquote(backend), options)
        end

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          @doc false
          def to_string!(%CalendarInterval{} = interval) do
            locale = unquote(backend).get_locale
            Cldr.Date.Interval.to_string!(interval, unquote(backend), locale: locale)
          end
        end

        @doc false
        def to_string!(%Elixir.Date.Range{} = interval) do
          locale = unquote(backend).get_locale
          Cldr.Date.Interval.to_string!(interval, unquote(backend), locale: locale)
        end

        @doc """
        Returns a `Date.Range` or `CalendarInterval` as
        a localised string.

        ## Arguments

        * `range` as either a`Date.Range.t` returned from `Date.range/2`
          or a `CalendarInterval.t`

        * `options` is a keyword list of options. The default is `[]`.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:date`, `:month_and_day`, `:month`
          and `:year_and_month`. The default is `:date`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

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

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-12-31])
            "Jan 1 – Dec 31, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12])
            "Jan 1 – 12, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long
            "Wed, Jan 1 – Sun, Jan 12, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-12-01]),
            ...> format: :long, style: :year_and_month
            "January – December 2020"

            iex> use CalendarInterval
            iex> #{inspect(__MODULE__)}.to_string! ~I"2020-01/12"
            "Jan 1 – Dec 31, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :short
            "1/1/2020 – 1/12/2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long, locale: "fr"
            "mer. 1 – dim. 12 janv. 2020"

        """
        @spec to_string!(Cldr.Interval.range(), Keyword.t()) ::
                String.t() | no_return

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          def to_string!(%CalendarInterval{} = interval, options) do
            locale = unquote(backend).get_locale
            options = Keyword.put_new(options, :locale, locale)
            Cldr.Date.Interval.to_string!(interval, unquote(backend), options)
          end
        end

        def to_string!(%Elixir.Date.Range{} = interval, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.Date.Interval.to_string!(interval, unquote(backend), options)
        end

        @doc false
        def to_string!(from, to) do
          locale = unquote(backend).get_locale
          Cldr.Date.Interval.to_string!(from, to, unquote(backend), locale: locale)
        end

        @doc """
        Returns a interval formed from two dates as
        a localised string.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.date` type.

        * `to` is any map that conforms to the
          `Calendar.date` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone date.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:date`, `:month_and_day`, `:month`
          and `:year_and_month`. The default is `:date`.

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
          date is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-12-31])
            "Jan 1 – Dec 31, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12])
            "Jan 1 – 12, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long
            "Wed, Jan 1 – Sun, Jan 12, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-12-01]),
            ...> format: :long, style: :year_and_month
            "January – December 2020"

            iex> use CalendarInterval
            iex> #{inspect(__MODULE__)}.to_string! ~I"2020-01/12"
            "Jan 1 – Dec 31, 2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :short
            "1/1/2020 – 1/12/2020"

            iex> #{inspect(__MODULE__)}.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
            ...> format: :long, locale: "fr"
            "mer. 1 – dim. 12 janv. 2020"

        """
        @spec to_string!(Elixir.Calendar.date() | nil, Elixir.Calendar.date() | nil, Keyword.t()) ::
                String.t() | no_return

        def to_string!(unquote(date) = from, unquote(date) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(nil = from, unquote(date) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(unquote(date) = from, nil = to, options) do
          do_to_string!(from, to, options)
        end

        def do_to_string!(from, to, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.Date.Interval.to_string!(from, to, unquote(backend), options)
        end
      end
    end
  end
end
