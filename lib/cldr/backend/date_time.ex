defmodule Cldr.DateAndTime.Backend do
  @moduledoc false

  def define_backend_modules(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule DateTime do
        @doc """
        Formats a DateTime according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

        ## Arguments

        * `datetime` is a `%DateTime{}` `or %NaiveDateTime{}`struct or any map that contains the keys
          `:year`, `:month`, `:day`, `:calendar`. `:hour`, `:minute` and `:second` with optional
          `:microsecond`.

        * `options` is a keyword list of options for formatting.

        ## Options

          * `format:` `:short` | `:medium` | `:long` | `:full` or a format string or
            any of the keys returned by `Cldr.DateTime.available_format_names`.
            The default is `:medium`

          * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

          * `number_system:` a number system into which the formatted date digits should
            be transliterated

          * `era: :variant` will use a variant for the era is one is available in the locale.
            In the "en" for example, the locale `era: :variant` will return "BCE" instead of "BC".

          * `period: :variant` will use a variant for the time period and flexible time period if
            one is available in the locale.  For example, in the "en" locale `period: :variant` will
            return "pm" instead of "PM"

        ## Returns

        * `{:ok, formatted_datetime}` or

        * `{:error, reason}`

        ## Examples

            iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string datetime
            {:ok, "Jan 1, 2000, 11:59:59 PM"}
            iex> #{inspect(__MODULE__)}.to_string datetime, locale: "en"
            {:ok, "Jan 1, 2000, 11:59:59 PM"}
            iex> #{inspect(__MODULE__)}.to_string datetime, format: :long, locale: "en"
            {:ok, "January 1, 2000, 11:59:59 PM UTC"}
            iex> #{inspect(__MODULE__)}.to_string datetime, format: :hms, locale: "en"
            {:ok, "11:59:59 PM"}
            iex> #{inspect(__MODULE__)}.to_string datetime, format: :full, locale: "en"
            {:ok, "Saturday, January 1, 2000, 11:59:59 PM GMT"}
            iex> #{inspect(__MODULE__)}.to_string datetime, format: :full, locale: "fr"
            {:ok, "samedi 1 janvier 2000, 23:59:59 UTC"}

        """
        @spec to_string(map, Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(date_time, options \\ []) do
          Cldr.DateTime.to_string(date_time, unquote(backend), options)
        end

        @doc """
        Formats a DateTime according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
        returning a formatted string or raising on error.

        ## Arguments

        * `datetime` is a `%DateTime{}` `or %NaiveDateTime{}`struct or any map that contains the keys
          `:year`, `:month`, `:day`, `:calendar`. `:hour`, `:minute` and `:second` with optional
          `:microsecond`.

        * `options` is a keyword list of options for formatting.

        ## Options

          * `format:` `:short` | `:medium` | `:long` | `:full` or a format string or
            any of the keys returned by `Cldr.DateTime.available_format_names` or a format string.
            The default is `:medium`

          * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

          * `number_system:` a number system into which the formatted date digits should
            be transliterated

          * `era: :variant` will use a variant for the era is one is available in the locale.
            In the "en" for example, the locale `era: :variant` will return "BCE" instead of "BC".

          * `period: :variant` will use a variant for the time period and flexible time period if
            one is available in the locale.  For example, in the "en" locale `period: :variant` will
            return "pm" instead of "PM"

        ## Returns

        * `formatted_datetime` or

        * raises an exception

        ## Examples

            iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string! datetime, locale: "en"
            "Jan 1, 2000, 11:59:59 PM"
            iex> #{inspect(__MODULE__)}.to_string! datetime, format: :long, locale: "en"
            "January 1, 2000, 11:59:59 PM UTC"
            iex> #{inspect(__MODULE__)}.to_string! datetime, format: :full, locale: "en"
            "Saturday, January 1, 2000, 11:59:59 PM GMT"
            iex> #{inspect(__MODULE__)}.to_string! datetime, format: :full, locale: "fr"
            "samedi 1 janvier 2000, 23:59:59 UTC"

        """
        @spec to_string!(map, Keyword.t()) :: String.t() | no_return
        def to_string!(date_time, options \\ []) do
          Cldr.DateTime.to_string!(date_time, unquote(backend), options)
        end
      end

      defmodule Date do
        @doc """
        Formats a date according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

        ## Arguments

        * `date` is a `%Date{}` struct or any map that contains the keys
          `year`, `month`, `day` and `calendar`

        * `options` is a keyword list of options for formatting.  The valid options are:

        ## Options

          * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
            The default is `:medium`

          * `locale:` any locale returned by `Cldr.known_locale_names/1`.
            The default is `Cldr.get_locale()`.

          * `number_system:` a number system into which the formatted date digits
            should be transliterated

        ## Returns

        * `{:ok, formatted_string}` or

        * `{:error, reason}`

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], format: :medium, locale: "en"
            {:ok, "Jul 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], locale: "en"
            {:ok, "Jul 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], format: :full, locale: "en"
            {:ok, "Monday, July 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], format: :short, locale: "en"
            {:ok, "7/10/17"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], format: :short, locale: "fr"
            {:ok, "10/07/2017"}

            iex> #{inspect(__MODULE__)}.to_string ~D[2017-07-10], format: :long, locale: "af"
            {:ok, "10 Julie 2017"}

        """
        @spec to_string(map, Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(date, options \\ []) do
          Cldr.Date.to_string(date, unquote(backend), options)
        end

        @doc """
        Formats a date according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

        ## Arguments

        * `date` is a `%Date{}` struct or any map that contains the keys
          `year`, `month`, `day` and `calendar`

        * `options` is a keyword list of options for formatting.

        ## Options

          * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
            The default is `:medium`

          * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

          * `number_system:` a number system into which the formatted date digits should
            be transliterated

        ## Returns

        * `formatted_date` or

        * raises an exception.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], format: :medium, locale: "en"
            "Jul 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], locale: "en"
            "Jul 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], format: :full,locale: "en"
            "Monday, July 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], format: :short, locale: "en"
            "7/10/17"

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], format: :short, locale: "fr"
            "10/07/2017"

            iex> #{inspect(__MODULE__)}.to_string! ~D[2017-07-10], format: :long, locale: "af"
            "10 Julie 2017"

        """
        @spec to_string!(map, Keyword.t()) :: String.t() | no_return
        def to_string!(date, options \\ []) do
          Cldr.Date.to_string!(date, unquote(backend), options)
        end
      end

      defmodule Time do
        @doc """
        Formats a time according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

        ## Returns

        * `{:ok, formatted_time}` or

        * `{:error, reason}`.

        ## Arguments

        * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
          `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

        * `options` is a keyword list of options for formatting.

        ## Options

        * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
           The default is `:medium`

        * `locale:` any locale returned by `Cldr.known_locale_names/1`.  The default is `
          Cldr.get_locale()`

        * `number_system:` a number system into which the formatted date digits should
          be transliterated

        * `era: :variant` will use a variant for the era is one is available in the locale.
          In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".

        * `period: :variant` will use a variant for the time period and flexible time period if
          one is available in the locale.  For example, in the "en" locale `period: :variant` will
          return "pm" instead of "PM"

        ## Examples

            iex> Cldr.Time.to_string ~T[07:35:13.215217]
            {:ok, "7:35:13 AM"}

            iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :short
            {:ok, "7:35 AM"}

            iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium, locale: "fr"
            {:ok, "07:35:13"}

            iex> Cldr.Time.to_string ~T[07:35:13.215217], format: :medium
            {:ok, "7:35:13 AM"}

            iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> Cldr.Time.to_string datetime, format: :long
            {:ok, "11:59:59 PM UTC"}

        """
        @spec to_string(map, Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(time, options \\ []) do
          Cldr.Time.to_string(time, unquote(backend), options)
        end

        @doc """
        Formats a time according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

        ## Arguments

        * `time` is a `%DateTime{}` or `%NaiveDateTime{}` struct or any map that contains the keys
          `hour`, `minute`, `second` and optionally `calendar` and `microsecond`

        * `options` is a keyword list of options for formatting.

        ## Options

          * `format:` `:short` | `:medium` | `:long` | `:full` or a format string.
             The default is `:medium`

          * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
            or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

          * `number_system:` a number system into which the formatted date digits should
            be transliterated

          * `era: :variant` will use a variant for the era is one is available in the locale.
            In the "en" locale, for example, `era: :variant` will return "BCE" instead of "BC".

          * `period: :variant` will use a variant for the time period and flexible time period if
            one is available in the locale.  For example, in the "en" locale `period: :variant` will
            return "pm" instead of "PM"

        ## Returns

        * `formatted_time_string` or

        * raises an exception.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! ~T[07:35:13.215217]
            "7:35:13 AM"

            iex> #{inspect(__MODULE__)}.to_string! ~T[07:35:13.215217], format: :short
            "7:35 AM"

            iex> #{inspect(__MODULE__)}.to_string ~T[07:35:13.215217], format: :short, period: :variant
            {:ok, "7:35 AM"}

            iex> #{inspect(__MODULE__)}.to_string! ~T[07:35:13.215217], format: :medium, locale: "fr"
            "07:35:13"

            iex> #{inspect(__MODULE__)}.to_string! ~T[07:35:13.215217], format: :medium
            "7:35:13 AM"

            iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string! datetime, format: :long
            "11:59:59 PM UTC"

        """
        @spec to_string!(map, Keyword.t()) :: String.t() | no_return
        def to_string!(time, options \\ []) do
          Cldr.Time.to_string!(time, unquote(backend), options)
        end
      end
    end
  end
end
