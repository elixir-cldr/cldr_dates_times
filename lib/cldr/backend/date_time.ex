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

        * `datetime` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
          one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
          `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
          and `:calendar` fields.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format string or
          any of the keys in the map returned by `Cldr.DateTime.Format.date_time_formats/3`.
          The default is `:medium`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
          this option is used to format the date part of the date time. This option is
          only acceptable if the `:format` option is not specified, or is specified as either
          `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
          then the date format is defined by the `:format` option.

        * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
          this option is used to format the time part of the date time. This option is
          only acceptable if the `:format` option is not specified, or is specified as either
          `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
          then the time format is defined by the `:format` option.

        * `:style` is either `:at` or `:default`. When set to `:at` the datetime may
          be formatted with a localised string representing `<date> at <time>` if such
          a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
          to see which formats have these variants.

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted datetime digits should
          be transliterated.

        * `:era` which, if set to `:variant`, will use a variant for the era if one
          is available in the requested locale. In the `:en` locale, for example, `era: :variant`
          will return `CE` instead of `AD` and `BCE` instead of `BC`.

        * `period: :variant` will use a variant for the time period and flexible time period if
          one is available in the locale.  For example, in the `:en` locale `period: :variant` will
          return "pm" instead of "PM".

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
        @spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(date_time, options \\ []) do
          Cldr.DateTime.to_string(date_time, unquote(backend), options)
        end

        @doc """
        Formats a DateTime according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
        returning a formatted string or raising on error.

        ## Arguments

        * `datetime` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
          one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
          `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
          and `:calendar` fields.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format string or
          any of the keys in the map returned by `Cldr.DateTime.Format.date_time_formats/3`.
          The default is `:medium`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
          this option is used to format the date part of the date time. This option is
          only acceptable if the `:format` option is not specified, or is specified as either
          `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
          then the date format is defined by the `:format` option.

        * `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
          this option is used to format the time part of the date time. This option is
          only acceptable if the `:format` option is not specified, or is specified as either
          `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
          then the time format is defined by the `:format` option.

        * `:style` is either `:at` or `:default`. When set to `:at` the datetime may
          be formatted with a localised string representing `<date> at <time>` if such
          a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
          to see which formats have these variants.

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted datetime digits should
          be transliterated.

        * `:era` which, if set to `:variant`, will use a variant for the era if one
          is available in the requested locale. In the `:en` locale, for example, `era: :variant`
          will return `CE` instead of `AD` and `BCE` instead of `BC`.

        * `period: :variant` will use a variant for the time period and flexible time period if
          one is available in the locale.  For example, in the `:en` locale `period: :variant` will
          return "pm" instead of "PM".

        ## Returns

        * `formatted_datetime` or

        * raises an exception.

        ## Examples

            iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string!(date_time, locale: :en)
            "Jan 1, 2000, 11:59:59 PM"
            iex> #{inspect(__MODULE__)}.to_string!(date_time, format: :long, locale: :en)
            "January 1, 2000, 11:59:59 PM UTC"
            iex> #{inspect(__MODULE__)}.to_string!(date_time, format: :full, locale: :en)
            "Saturday, January 1, 2000, 11:59:59 PM GMT"
            iex> #{inspect(__MODULE__)}.to_string!(date_time, format: :full, locale: :fr)
            "samedi 1 janvier 2000, 23:59:59 UTC"

        """
        @spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) :: String.t() | no_return
        def to_string!(date_time, options \\ []) do
          Cldr.DateTime.to_string!(date_time, unquote(backend), options)
        end
      end

      defmodule Date do
        @doc """
        Formats a date according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

        ## Arguments

        * `date` is a `t:Date.t/0` struct or any map that contains one or more
          of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
          or a format string. The default is `:medium` for full dates (that is,
          dates having `:year`, `:month`, `:day` and `:calendar` fields). The
          default for partial dates is to derive a candidate format id from the date and
          find the best match from the formats returned by
          `Cldr.Date.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:locale` any locale returned by `Cldr.known_locale_names/1`.
          The default is `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted date digits
          should be transliterated.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.Date.available_formats/3`
          to see which formats have these variants. Currently no date-specific
          formats have such variants but they may in the future.

        * `:era` which, if set to `:variant`, will use a variant for the era if one
          is available in the requested locale. In the `:en` locale, for example, `era: :variant`
          will return `CE` instead of `AD` and `BCE` instead of `BC`.

        ## Returns

        * `{:ok, formatted_string}` or

        * `{:error, reason}`

        ## Examples

            # Full dates have the default format `:medium`
            iex> #{inspect(__MODULE__)}.to_string(~D[2017-07-10], locale: :en)
            {:ok, "Jul 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-07-10], format: :medium, locale: :en)
            {:ok, "Jul 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-07-10], format: :full, locale: :en)
            {:ok, "Monday, July 10, 2017"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-07-10], format: :short, locale: :en)
            {:ok, "7/10/17"}

            iex> #{inspect(__MODULE__)}.to_string(~D[2017-07-10], format: :short, locale: "fr")
            {:ok, "10/07/2017"}

            # A partial date with a derived "best match" format
            iex> #{inspect(__MODULE__)}.to_string(%{year: 2024, month: 6}, locale: "fr")
            {:ok, "06/2024"}

            # A partial date with a best match CLDR-defined format
            iex> #{inspect(__MODULE__)}.to_string(%{year: 2024, month: 6}, format: :yMMM, locale: "fr")
            {:ok, "juin 2024"}

            # Sometimes the available date fields can't be mapped to an available
            # CLDR defined format.
            iex> #{inspect(__MODULE__)}.to_string(%{year: 2024, day: 3}, locale: "fr")
            {:error,
             {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :dy"}}

        """
        @spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(date, options \\ []) do
          Cldr.Date.to_string(date, unquote(backend), options)
        end

        @doc """
        Formats a date according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
        or raises an exception.

        ## Arguments

        * `date` is a `t:Date.t/0` struct or any map that contains one or more
          of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
          or a format string. The default is `:medium` for full dates (that is,
          dates having `:year`, `:month`, `:day` and `:calendar` fields). The
          default for partial dates is to derive a candidate format id from the date and
          find the best match from the formats returned by
          `Cldr.Date.available_formats/3`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:locale` any locale returned by `Cldr.known_locale_names/1`.
          The default is `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted date digits
          should be transliterated.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.Date.available_formats/3`
          to see which formats have these variants. Currently no date-specific
          formats have such variants but they may in the future.

        * `:era` which, if set to `:variant`, will use a variant for the era if one
          is available in the requested locale. In the `:en` locale, for example, `era: :variant`
          will return `CE` instead of `AD` and `BCE` instead of `BC`.

        ## Returns

        * `formatted_date` or

        * raises an exception.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string!(~D[2017-07-10], locale: :en)
            "Jul 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string!(~D[2017-07-10], format: :medium, locale: :en)
            "Jul 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string!(~D[2017-07-10], format: :full, locale: :en)
            "Monday, July 10, 2017"

            iex> #{inspect(__MODULE__)}.to_string!(~D[2017-07-10], format: :short, locale: :en)
            "7/10/17"

            iex> #{inspect(__MODULE__)}.to_string!(~D[2017-07-10], format: :short, locale: "fr")
            "10/07/2017"

            # A partial date with a derived "best match" format
            iex> #{inspect(__MODULE__)}.to_string!(%{year: 2024, month: 6}, locale: "fr")
            "06/2024"

            # A partial date with a best match CLDR-defined format
            iex> #{inspect(__MODULE__)}.to_string!(%{year: 2024, month: 6}, format: :yMMM, locale: "fr")
            "juin 2024"

        """
        @spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) ::
                String.t() | no_return

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

        * `time` is a `t:Time.t/0` struct or any map that contains
          one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
          `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
          or a format string. The default is `:medium` for full times (that is,
          times having `:hour`, `:minute` and `:second` fields). The
          default for partial times is to derive a candidate format from the time and
          find the best match from the formats returned by
          `Cldr.Time.available_formats/2`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:locale` any locale returned by `Cldr.known_locale_names/1`.  The default is
          `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted date digits should
          be transliterated.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.Time.available_formats/3`
          to see which formats have these variants.

        * `period: :variant` will use a variant for the time period and flexible time period if
          one is available in the locale.  For example, in the `:en` locale `period: :variant` will
          return "pm" instead of "PM".

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string(~T[07:35:13.215217])
            {:ok, "7:35:13 AM"}

            iex> #{inspect(__MODULE__)}.to_string(~T[07:35:13.215217], format: :short)
            {:ok, "7:35 AM"}

            iex> #{inspect(__MODULE__)}.to_string(~T[07:35:13.215217], format: :short, period: :variant)
            {:ok, "7:35 am"}

            iex> #{inspect(__MODULE__)}.to_string(~T[07:35:13.215217], format: :medium, locale: :fr)
            {:ok, "07:35:13"}

            iex> #{inspect(__MODULE__)}.to_string(~T[07:35:13.215217], format: :medium)
            {:ok, "7:35:13 AM"}

            iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string(date_time, format: :long)
            {:ok, "11:59:59 PM UTC"}

            # A partial time with a best match CLDR-defined format
            iex> #{inspect(__MODULE__)}.to_string(%{hour: 23, minute: 11})
            {:ok, "11:11 PM"}

            # Sometimes the available time fields can't be mapped to an available
            # CLDR defined format.
            iex> #{inspect(__MODULE__)}.to_string(%{minute: 11})
            {:error,
             {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :m"}}

        """
        @spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, String.t()}}

        def to_string(time, options \\ []) do
          Cldr.Time.to_string(time, unquote(backend), options)
        end

        @doc """
        Formats a time according to a format string
        as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
        or raises an exception.

        ## Arguments

        * `time` is a `t:Time.t/0` struct or any map that contains
          one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
          `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

        * `options` is a keyword list of options for formatting.

        ## Options

        * `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
          or a format string. The default is `:medium` for full times (that is,
          times having `:hour`, `:minute` and `:second` fields). The
          default for partial times is to derive a candidate format from the time and
          find the best match from the formats returned by
          `Cldr.Time.available_formats/2`. See [here](README.md#date-time-and-datetime-localization-formats)
          for more information about specifying formats.

        * `:locale` any locale returned by `Cldr.known_locale_names/1`.  The default is
          `Cldr.get_locale/0`.

        * `:number_system` a number system into which the formatted date digits should
          be transliterated.

        * `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
          formats have two variants - one using Unicode spaces (typically non-breaking space) and
          another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
          use cases and is not recommended. See `Cldr.Time.available_formats/3`
          to see which formats have these variants.

        * `period: :variant` will use a variant for the time period and flexible time period if
          one is available in the locale.  For example, in the `:en` locale `period: :variant` will
          return "pm" instead of "PM".

        ## Returns

        * `formatted_time_string` or

        * raises an exception.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string!(~T[07:35:13.215217])
            "7:35:13 AM"

            iex> #{inspect(__MODULE__)}.to_string!(~T[07:35:13.215217], format: :short)
            "7:35 AM"

            iex> #{inspect(__MODULE__)}.to_string!(~T[07:35:13.215217], format: :short, period: :variant)
            "7:35 am"

            iex> #{inspect(__MODULE__)}.to_string!(~T[07:35:13.215217], format: :medium, locale: :fr)
            "07:35:13"

            iex> #{inspect(__MODULE__)}.to_string!(~T[07:35:13.215217], format: :medium)
            "7:35:13 AM"

            iex> {:ok, datetime} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
            iex> #{inspect(__MODULE__)}.to_string! datetime, format: :long
            "11:59:59 PM UTC"

            # A partial time with a best match CLDR-defined format
            iex> #{inspect(__MODULE__)}.to_string!(%{hour: 23, minute: 11})
            "11:11 PM"

        """
        @spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) ::
                String.t() | no_return

        def to_string!(time, options \\ []) do
          Cldr.Time.to_string!(time, unquote(backend), options)
        end
      end
    end
  end
end
