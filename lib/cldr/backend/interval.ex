defmodule Cldr.Interval.Backend do
  @moduledoc false

  def define_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule Interval do
        @moduledoc """
        Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
        shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
        to take a start and end date, time or datetime plus a formatting pattern
        and use that information to produce a localized format.

        The interval functions in the library will determine the calendar
        field with the greatest difference between the two datetimes before using the
        format pattern.

        For example, the greatest difference in "Jan 10-12, 2008" is the day field, while
        the greatest difference in "Jan 10 - Feb 12, 2008" is the month field. This is used to
        pick the exact pattern to be used.

        See `Cldr.Interval` for further detail.

        """

        @doc """
        Returns a string representing the formatted
        interval formed by two date.

        ## Arguments

        * `from` and `to` are any maps that conform to the
          `Calendar.date` type which means a map that includes
          at least the keys `:year`, `:month` and `:day`.
          Instead of `from` and `to`, a `Date.Range.t` or
          `CalendarInterval.t` can be provided.

        * `options` is a keyword list of options. The default is `[]`.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The valid
          styles depends on whether formatting is for a date, time or datetime.
          Since the functions in this module will make a determination as
          to which formatter to be used based upon the data passed to them
          it is recommended the style option be ommitted. If styling is important
          then call `to_string/3` directly on `Cldr.Date.Interval`, `Cldr.Time.Interval`
          or `Cldr.DateTime.Interval`.

          * For a date the alternatives are `:date`, `:month_and_day`, `:month`
            and `:year_and_month`. The default is `:date`.

          * For a time the alternatives are `:time`, `:zone` and
            `:flex`. The default is `:time`

          * For a datetime there are no style options, the default
            for each of the date and time part is used

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        ## Returns

        * `{:ok, string}` or

        * `{:error, {exception, reason}}`

        ## Notes

        * `to_string/3` will decide which formatter to call based upon
          the aguments provided to it.

          * A `Date.Range.t` will call `Cldr.Date.Interval.to_string/3`

          * A `CalendarInterval` will call `Cldr.Date.Interval.to_string/3`
            if its `:precision` is `:year`, `:month` or `:day`. Othersie
            it will call `Cldr.Time.Interval.to_string/3`

          * If `from` and `to` both conform to the `Calendar.datetime()`
            type then `Cldr.DateTime.Interval.to_string/3` is called

          * Otherwise if `from` and `to` conform to the `Calendar.date()`
            type then `Cldr.Date.Interval.to_string/3` is called

          * Otherwise if `from` and `to` conform to the `Calendar.time()`
            type then `Cldr.Time.Interval.to_string/3` is called

        * `CalendarInterval` support requires adding the
          dependency [calendar_interval](https://hex.pn/packages/calendar_interval)
          to the `deps` configuration in `mix.exs`.

        * For more information on interval format string
          see `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configuration locale name and `:gregorian`
          is the underlying `CLDR` calendar type.

        * In the case where `from` and `to` are equal, a single
          date, time or datetime is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-12-31]
            {:ok, "Jan 1 – Dec 31, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12]
            {:ok, "Jan 1 – 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-01-12],
            ...> format: :long
            {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2020-01-01], ~D[2020-12-01],
            ...> format: :long, style: :year_and_month
            {:ok, "January – December 2020"}

            iex> use CalendarInterval
            iex> #{inspect(__MODULE__)}.to_string ~I"2020-01-01/12",
            ...> format: :long
            {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-12-01 10:05:00.0Z],
            ...> format: :long
            {:ok, "January 1, 2020 at 12:00:00 AM UTC – December 1, 2020 at 10:05:00 AM UTC"}

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:05:00.0Z],
            ...> format: :long
            {:ok, "January 1, 2020 at 12:00:00 AM UTC – 10:05:00 AM UTC"}

        """
        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          def to_string(%CalendarInterval{} = interval) do
            Cldr.Interval.to_string(interval, unquote(backend), [])
          end
        end

        def to_string(%Elixir.Date.Range{} = interval) do
          Cldr.Interval.to_string(interval, unquote(backend), [])
        end

        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          def to_string(%CalendarInterval{} = interval, options) do
            Cldr.Interval.to_string(interval, unquote(backend), options)
          end
        end

        def to_string(%Elixir.Date.Range{} = interval, options) do
          Cldr.Interval.to_string(interval, unquote(backend), options)
        end

        def to_string(from, to) do
          Cldr.Interval.to_string(from, to, unquote(backend), [])
        end

        def to_string(from, to, options) do
          Cldr.Interval.to_string(from, to, unquote(backend), options)
        end
      end
    end
  end
end
