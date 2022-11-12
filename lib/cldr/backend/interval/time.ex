defmodule Cldr.Time.Interval.Backend do
  @moduledoc false

  def define_time_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule Time.Interval do
        @moduledoc """
        Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
        shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
        to take a start and end date, time or datetime plus a formatting pattern
        and use that information to produce a localized format.

        See `Cldr.Interval.to_string/3` and `Cldr.Time.Interval.to_string/3`

        """

        import Cldr.Calendar,
          only: [
            time: 0
          ]

        @doc """
        Returns a string representing the formatted
        interval formed by two times.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.time` type.

        * `to` is any map that conforms to the
          `Calendar.time` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone time.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:time`, `:zone`,
          and `:flex`. The default is `:time`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        ## Returns

        * `{:ok, string}` or

        * `{:error, {exception, reason}}`

        ## Notes

        * For more information on interval format string
          see `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configured locale name and `:gregorian`
          is the underlying CLDR calendar type.

        * In the case where `from` and `to` are equal, a single
          time is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], ~T[10:03:00], format: :short
            {:ok, "10 – 10"}

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], ~T[10:03:00], format: :medium
            {:ok, "10:00 – 10:03 AM"}

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], ~T[10:03:00], format: :long
            {:ok, "10:00 – 10:03 AM"}

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], ~T[10:03:00],
            ...> format: :long, style: :flex
            {:ok, "10:00 – 10:03 in the morning"}

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
            ...> format: :long, style: :flex
            {:ok, "12:00 – 10:00 in the morning"}

            iex> #{inspect(__MODULE__)}.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
            ...> format: :long, style: :zone
            {:ok, "12:00 – 10:00 AM Etc/UTC"}

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], ~T[10:03:00],
            ...> format: :long, style: :flex, locale: "th"
            {:ok, "10:00 – 10:03 ในตอนเช้า"}

            iex> #{inspect(__MODULE__)}.to_string ~T[10:00:00], nil
            {:ok, "10:00:00 AM –"}

        """
        @spec to_string(Elixir.Calendar.time() | nil, Elixir.Calendar.time() | nil, Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(from, to, options \\ [])

        def to_string(unquote(time()) = from, unquote(time()) = to, options) do
          do_to_string(from, to, options)
        end

        def to_string(nil = from, unquote(time()) = to, options) do
          do_to_string(from, to, options)
        end

        def to_string(unquote(time()) = from, nil = to, options) do
          do_to_string(from, to, options)
        end

        def do_to_string(from, to, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.Time.Interval.to_string(from, to, unquote(backend), options)
        end

        @doc """
        Returns a string representing the formatted
        interval formed by two times or raises an
        exception.

        ## Arguments

        * `from` is any map that conforms to the
          `Calendar.time` type.

        * `to` is any map that conforms to the
          `Calendar.time` type. `to` must occur
          on or after `from`.

        * `options` is a keyword list of options. The default is `[]`.

        Either `from` or `to` may also be `nil`, in which case an
        open interval is formatted and the non-nil item is formatted
        as a standalone time.

        ## Options

        * `:format` is one of `:short`, `:medium` or `:long` or a
          specific format type or a string representing of an interval
          format. The default is `:medium`.

        * `:style` supports dfferent formatting styles. The
          alternatives are `:time`, `:zone`,
          and `:flex`. The default is `:time`.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `#{backend}.get_locale/0`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        ## Returns

        * `string` or

        * raises an exception

        ## Notes

        * For more information on interval format string
          see `Cldr.Interval`.

        * The available predefined formats that can be applied are the
          keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
          where `"en"` can be replaced by any configured locale name and `:gregorian`
          is the underlying CLDR calendar type.

        * In the case where `from` and `to` are equal, a single
          time is formatted instead of an interval

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! ~T[10:00:00], ~T[10:03:00], format: :short
            "10 – 10"

            iex> #{inspect(__MODULE__)}.to_string! ~T[10:00:00], ~T[10:03:00], format: :medium
            "10:00 – 10:03 AM"

            iex> #{inspect(__MODULE__)}.to_string! ~T[10:00:00], ~T[10:03:00], format: :long
            "10:00 – 10:03 AM"

            iex> #{inspect(__MODULE__)}.to_string! ~T[10:00:00], ~T[10:03:00],
            ...> format: :long, style: :flex
            "10:00 – 10:03 in the morning"

            iex> #{inspect(__MODULE__)}.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
            ...> format: :long, style: :flex
            "12:00 – 10:00 in the morning"

            iex> #{inspect(__MODULE__)}.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:00:00.0Z],
            ...> format: :long, style: :zone
            "12:00 – 10:00 AM Etc/UTC"

            iex> #{inspect(__MODULE__)}.to_string! ~T[10:00:00], ~T[10:03:00],
            ...> format: :long, style: :flex, locale: "th"
            "10:00 – 10:03 ในตอนเช้า"

        """
        @spec to_string!(Elixir.Calendar.time() | nil, Elixir.Calendar.time() | nil, Keyword.t()) ::
                String.t() | no_return()

        def to_string!(from, to, options \\ [])

        def to_string!(unquote(time()) = from, unquote(time()) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(nil = from, unquote(time()) = to, options) do
          do_to_string!(from, to, options)
        end

        def to_string!(unquote(time()) = from, nil = to, options) do
          do_to_string!(from, to, options)
        end

        def do_to_string!(from, to, options) do
          locale = unquote(backend).get_locale
          options = Keyword.put_new(options, :locale, locale)
          Cldr.Time.Interval.to_string!(from, to, unquote(backend), options)
        end
      end
    end
  end
end
