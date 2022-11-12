defmodule Cldr.Interval do
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

  ### Interval Format Styles

  CLDR provides a set of format types that map to a concrete format string.
  To simplify the developer experience, `ex_cldr_dates_times` groups these
  formats into `styles` and `format types`.

  Format styles group different CLDR formats into similar types. These format
  styles can be seen by examining the output below:

  ```elixir
  iex> Cldr.Date.Interval.styles
  %{
    date: %{long: :y_mmm_ed, medium: :y_mm_md, short: :y_md},
    month: %{long: :mmm, medium: :mmm, short: :m},
    month_and_day: %{long: :mmm_ed, medium: :mm_md, short: :md},
    year_and_month: %{long: :y_mmmm, medium: :y_mmm, short: :y_m}
  }

  iex> Cldr.Time.Interval.styles
  %{
    flex: %{long: :bhm, medium: :bhm, short: :bh},
    time: %{long: :hm, medium: :hm, short: :h},
    zone: %{long: :hmv, medium: :hmv, short: :hv}
  }
  ```

  Here the format style is the key if the map: `:date`, `:month`,
  `:month_and_day` and `year_and_month`.

  These are then mapped to interval formats.

  ### Interval formats

  In a manner similar to formatting individual dates, times and datetimes, format
  types are introduced to simplify common usage. For all intervals the following
  format types are;

  * `:short`
  * `:medium` (the default)
  * `:long`

  In each case, the mapping is from a style to a format type and then of
  resolves to a native CLDR format map.

  These maps can be examined as follows where `"en"` is any configured
  locale name and `:gregorian` is the underlying CLDR calendar type. In
  common use the `:gregorian` calendar is the standard.  However other
  calendar types are also supported. For example:

  ```elixir
  iex> Cldr.known_calendars
  [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
   :gregorian, :hebrew, :indian, :islamic, :islamic_civil, :islamic_rgsa,
   :islamic_tbla, :islamic_umalqura, :japanese, :persian, :roc]
  ```

  To examine the available interval formats, `Cldr.DateTime.Format.interval_formats/2`
  can be used although its use is primarily internal to the implementation of
  `to_string/3` and would not normally be called directly.

  ```elixir
  Cldr.DateTime.Format.interval_formats "en", :gregorian
  => {:ok,
       %{
         ...
         h: %{h: ["HH – ", "HH"]},
         hm: %{h: ["HH:mm – ", "HH:mm"], m: ["HH:mm – ", "HH:mm"]},
         hmv: %{h: ["HH:mm – ", "HH:mm v"], m: ["HH:mm – ", "HH:mm v"]},
         hv: %{a: ["h a – ", "h a v"], h: ["h – ", "h a v"]},
         m: %{m: ["M – ", "M"]},
         m_ed: %{d: ["E, M/d – ", "E, M/d"], m: ["E, M/d – ", "E, M/d"]},
         md: %{d: ["M/d – ", "M/d"], m: ["M/d – ", "M/d"]},
         mm_md: %{d: ["MMM d – ", "d"], m: ["MMM d – ", "MMM d"]},
         mmm: %{m: ["MMM – ", "MMM"]},
         mmm_ed: %{d: ["E, MMM d – ", "E, MMM d"], m: ["E, MMM d – ", "E, MMM d"]},
         y: %{y: ["y – ", "y"]},
         y_m: %{m: ["M/y – ", "M/y"], y: ["M/y – ", "M/y"]},
         y_m_ed: %{
           d: ["E, M/d/y – ", "E, M/d/y"],
           m: ["E, M/d/y – ", "E, M/d/y"],
           y: ["E, M/d/y – ", "E, M/d/y"]
         },
         y_md: %{
           d: ["M/d/y – ", "M/d/y"],
           m: ["M/d/y – ", "M/d/y"],
           y: ["M/d/y – ", "M/d/y"]
         },
         y_mm_md: %{
           d: ["MMM d – ", "d, y"],
           m: ["MMM d – ", "MMM d, y"],
           y: ["MMM d, y – ", "MMM d, y"]
         },
         ...
       }
     }
  ```

  At this point we can see that the path to resolving a format is:

  * Apply the format style. For dates, this is `:date`
  * Apply the format type. For dates, the default is `:medium`

  This will then return a map such as:

  ```elixir
  %{
     d: ["MMM d – ", "d, y"],
     m: ["MMM d – ", "MMM d, y"],
     y: ["MMM d, y – ", "MMM d, y"]
   }
  ```

  ### The field with the greatest difference

  There remains one more choice to make - and that choice is made
  based upon the highest order date field that is different between the
  `from` and `to` dates.

  With two dates `2020-02-02` and `2021-01-01` the highest order
  difference is `:year`. With `2020-02-02` and `2020-01-01` it is `:month`.

  ### Formatting the interval

  Using this `greatest difference` information we can now resolve the
  final format. With the `:year` field being the greatest difference then
  the format is `y: ["MMM d, y – ", "MMM d, y"]`.

  Finally, formatting can proceed for the `from` date being formatted with
  `"MMM d, y – "` and the `to` date being formatted with `"MMM d, y"` and the
  two results then being concatenated to form the final string.

  ### Other ways to specify an interval format

  So far we have considered formats that a resolved from standard styles
  and format types. This is the typical usage and they are specified
  as parameters to the `to_string/3` function. For example:

  ```elixir
  iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr
  {:ok, "Jan 1 – 12, 2020"}

  iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr, format: :long
  {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

  iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
  ...> style: :month_and_day
  {:ok, "Jan 1 – 12"}
  ```

  ### Direct use of CLDR format types

  It is also possible to directly specify the CLDR format type. For example:
  ```elixir
  iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr, format: :gy_mm_md
  {:ok, "Jan 1 – 12, 2020 AD"}
  ```

  ### Using format strings

  In the unusual situation where one of the standard format styles and types does
  not meet requirements, a format string can also be specified. For example:

  ```elixir
  iex> Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
  ...> format: "E, M/d/y – E, M/d/y"
  {:ok, "Wed, 1/1/2020 – Sun, 1/12/2020"}
  ```

  In this case, the steps to formatting are:

  1. Split the format string at the point at which the first repeating
  formatting code is detected. In the pattern above it is where the second `E`
  is detected. The result in this case will be `["E, M/d/y – ", "E, M/d/y"]`
  For the purposes of splitting, duplicate are ignored. Therefore
  "EEE, M/d/y – E, M/d/y" will split into `["EEE, M/d/y – ", "E, M/d/y"]`.

  2. Each part of the pattern is parsed

  3. The two dates, times or datetimes are formatted

  This is a more expensive operation than using the predefined styles and
  format types since the underlying formats for these types are precompiled
  into an efficient runtime format.

  ### Configuring precompiled interval formats

  If there is a requirement for repeated use of format strings
  then they can be configured in the backend module so that they are
  precompiled and therefore not suffer a runtime performance penaly.

  In a backend module, configure the required formats as a list under the
  `:precompile_interval_formats` key:

  ```elixir
  defmodule MyApp.Cldr do
    use Cldr,
      locales: ["en", "fr"],
      default_locale: "en",
      precompile_interval_formats: ["E, MMM d/y – d/y"]
  end
  ```

  """

  @typedoc "A Date.Range or CalendarInterval range"
  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @type range :: Date.Range.t() | CalendarInterval.t()
  else
    @type range :: Date.Range.t()
  end

  @typedoc "Any date, time or datetime"
  @type datetime ::
          Calendar.date()
          | Calendar.datetime()
          | Calendar.naive_datetime()
          | Calendar.time()

  import Cldr.Calendar,
    only: [
      date: 0,
      datetime: 0,
      time: 0
    ]

  import Kernel,
    except: [
      to_string: 1
    ]

  # Single argument version.
  # Derive backend and locale

  @doc false
  def to_string(%Date.Range{} = range) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(range, backend, locale: locale)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{} = interval) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(date()) = from, unquote(date()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(time()) = from, unquote(time()) = to) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, nil)
    to_string(from, to, backend, locale: locale)
  end

  # Dual argument version with backend
  def to_string(%Date.Range{} = range, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(range, backend, locale: locale)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{} = interval, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string(interval, backend, locale: locale)
    end
  end

  @doc false
  def to_string(unquote(date()) = from, unquote(date()) = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  def to_string(unquote(time()) = from, unquote(time()) = to, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string(from, to, backend, locale: locale)
  end

  # Dual argument version with options
  def to_string(%Date.Range{} = range, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    to_string(range, backend, locale: Keyword.put_new(options, :locale, locale))
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{} = interval, options) when is_list(options) do
      {locale, backend} = Cldr.locale_and_backend_from(options)
      to_string(interval, backend, Keyword.put_new(options, :locale, locale))
    end
  end

  def to_string(unquote(date()) = from, unquote(date()) = to, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(from, to, backend, options)
  end

  def to_string(unquote(time()) = from, unquote(time()) = to, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string(from, to, backend, options)
  end

  @doc """
  Returns a `Date.Range` or `CalendarInterval` as
  a localised string.

  ## Arguments

  * `range` is either a `Date.Range.t` returned from `Date.range/2`
    or a `CalendarInterval.t`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The valid
    styles depends on whether formatting is for a date, time or datetime.
    Since the functions in this module will make a determination as
    to which formatter to be used based upon the data passed to them
    it is recommended the style option be omitted. If styling is important
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
    the arguments provided to it.

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
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date, time or datetime is formatted instead of an interval

  ## Examples

      iex> Cldr.Interval.to_string Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long
      {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

      iex> use CalendarInterval
      iex> Cldr.Interval.to_string ~I"2020-01-01/12", MyApp.Cldr,
      ...> format: :long
      {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

  """
  @spec to_string(range, Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(%Date.Range{first: first, last: last}, backend, options) do
    Cldr.Date.Interval.to_string(first, last, backend, options)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:year, :month, :day] do
      Cldr.Date.Interval.to_string(from, to, backend, options)
    end

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:hour, :minute] do
      from = %{from | second: 0, microsecond: {0, 6}}
      to = %{to | second: 0, microsecond: {0, 6}}
      Cldr.DateTime.Interval.to_string(from, to, backend, options)
    end

    def to_string(%CalendarInterval{first: from, last: to, precision: precision}, backend, options)
        when precision in [:second, :microsecond] do
      from = %{from | microsecond: {0, 6}}
      to = %{to | microsecond: {0, 6}}
      Cldr.DateTime.Interval.to_string(from, to, backend, options)
    end
  end

  @doc false
  def to_string(from, to, backend, options \\ [])

  @doc """
  Returns a string representing the formatted
  interval formed by two dates.

  ## Arguments

  * `from` is any map that conforms to the
    any one of the `Calendar` types.

  * `to` is any map that conforms to the
    any one of the `Calendar` types. `to` must
    occur on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The valid
    styles depends on whether formatting is for a date, time or datetime.
    Since the functions in this module will make a determination as
    to which formatter to be used based upon the data passed to them
    it is recommended the style option be omitted. If styling is important
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
    the arguments provided to it.

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
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date, time or datetime is formatted instead of an interval

  ## Examples

      iex> Cldr.Interval.to_string ~D[2020-01-01], ~D[2020-12-31], MyApp.Cldr
      {:ok, "Jan 1 – Dec 31, 2020"}

      iex> Cldr.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr
      {:ok, "Jan 1 – 12, 2020"}

      iex> Cldr.Interval.to_string ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long
      {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

      iex> Cldr.Interval.to_string ~D[2020-01-01], ~D[2020-12-01], MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      {:ok, "January – December 2020"}

      iex> Cldr.Interval.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-12-01 10:05:00.0Z], MyApp.Cldr,
      ...> format: :long
      {:ok, "January 1, 2020, 12:00:00 AM UTC – December 1, 2020, 10:05:00 AM UTC"}

      iex> Cldr.Interval.to_string ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:05:00.0Z], MyApp.Cldr,
      ...> format: :long
      {:ok, "January 1, 2020, 12:00:00 AM UTC – 10:05:00 AM UTC"}

  """
  @spec to_string(datetime, datetime, Cldr.backend(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {module, String.t()}}

  def to_string(unquote(datetime()) = from, unquote(datetime()) = to, backend, options) do
    Cldr.DateTime.Interval.to_string(from, to, backend, options)
  end

  def to_string(unquote(date()) = from, unquote(date()) = to, backend, options) do
    Cldr.Date.Interval.to_string(from, to, backend, options)
  end

  def to_string(unquote(time()) = from, unquote(time()) = to, backend, options) do
    Cldr.Time.Interval.to_string(from, to, backend, options)
  end

  @doc false
  def to_string!(%Date.Range{} = range, backend) when is_atom(backend) do
    {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
    to_string!(range, backend, locale: locale)
  end

  @doc false
  def to_string!(%Date.Range{} = range, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    options = Keyword.put_new(options, :locale, locale)
    to_string!(range, backend, options)
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    @doc false
    def to_string!(%CalendarInterval{} = range, backend) when is_atom(backend) do
      {locale, backend} = Cldr.locale_and_backend_from(nil, backend)
      to_string!(range, backend, locale: locale)
    end

    @doc false
    def to_string!(%CalendarInterval{} = range, options) when is_list(options) do
      {locale, backend} = Cldr.locale_and_backend_from(options)
      options = Keyword.put_new(options, :locale, locale)
      to_string!(range, backend, options)
    end
  end

  @doc """
  Returns a `Date.Range` or `CalendarInterval` as
  a localised string or raises an exception.

  ## Arguments

  * `range` is either a `Date.Range.t` returned from `Date.range/2`
    or a `CalendarInterval.t`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module.

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The valid
    styles depends on whether formatting is for a date, time or datetime.
    Since the functions in this module will make a determination as
    to which formatter to be used based upon the data passed to them
    it is recommended the style option be omitted. If styling is important
    then call `to_string/3` directly on `Cldr.Date.Interval`, `Cldr.Time.Interval`
    or `Cldr.DateTime.Interval`.

    * For a date the alternatives are `:date`, `:month_and_day`, `:month`
      and `:year_and_month`. The default is `:date`.

    * For a time the alternatives are `:time`, `:zone` and
      `:flex`. The default is `:time`.

    * For a datetime there are no style options, the default
      for each of the date and time part is used.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

  * `number_system:` a number system into which the formatted date digits should
    be transliterated.

  ## Returns

  * `string` or

  * raises an exception

  ## Notes

  * `to_string/3` will decide which formatter to call based upon
    the arguments provided to it.

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
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date, time or datetime is formatted instead of an interval

  ## Examples

      iex> use CalendarInterval
      iex> Cldr.Interval.to_string! ~I"2020-01-01/12", MyApp.Cldr,
      ...> format: :long
      "Wed, Jan 1 – Sun, Jan 12, 2020"

      iex> Cldr.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]), MyApp.Cldr,
      ...> format: :long
      "Wed, Jan 1 – Sun, Jan 12, 2020"

  """
  @spec to_string!(range, Cldr.backend(), Keyword.t()) :: String.t() | no_return()

  def to_string!(%Date.Range{} = range, backend, options) do
    case to_string(range, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  if Cldr.Code.ensure_compiled?(CalendarInterval) do
    def to_string!(%CalendarInterval{} = range, backend, options) do
      case to_string(range, backend, options) do
        {:ok, string} -> string
        {:error, {exception, reason}} -> raise exception, reason
      end
    end
  end

  @doc """
  Returns a string representing the formatted
  interval formed by two dates or raises an
  exception.

  ## Arguments

  * `from` is any map that conforms to the
    any one of the `Calendar` types.

  * `to` is any map that conforms to the
    any one of the `Calendar` types. `to` must
    occur on or after `from`.

  * `backend` is any module that includes `use Cldr` and
    is therefore a `Cldr` backend module

  * `options` is a keyword list of options. The default is `[]`.

  ## Options

  * `:format` is one of `:short`, `:medium` or `:long` or a
    specific format type or a string representing of an interval
    format. The default is `:medium`.

  * `:style` supports dfferent formatting styles. The valid
    styles depends on whether formatting is for a date, time or datetime.
    Since the functions in this module will make a determination as
    to which formatter to be used based upon the data passed to them
    it is recommended the style option be omitted. If styling is important
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
    the arguments provided to it.

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
    dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
    to the `deps` configuration in `mix.exs`.

  * For more information on interval format string
    see `Cldr.Interval`.

  * The available predefined formats that can be applied are the
    keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
    where `"en"` can be replaced by any configuration locale name and `:gregorian`
    is the underlying CLDR calendar type.

  * In the case where `from` and `to` are equal, a single
    date, time or datetime is formatted instead of an interval

  ## Examples

      iex> Cldr.Interval.to_string! ~D[2020-01-01], ~D[2020-12-31], MyApp.Cldr
      "Jan 1 – Dec 31, 2020"

      iex> Cldr.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr
      "Jan 1 – 12, 2020"

      iex> Cldr.Interval.to_string! ~D[2020-01-01], ~D[2020-01-12], MyApp.Cldr,
      ...> format: :long
      "Wed, Jan 1 – Sun, Jan 12, 2020"

      iex> Cldr.Interval.to_string! ~D[2020-01-01], ~D[2020-12-01], MyApp.Cldr,
      ...> format: :long, style: :year_and_month
      "January – December 2020"

      iex> Cldr.Interval.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-12-01 10:05:00.0Z], MyApp.Cldr,
      ...> format: :long
      "January 1, 2020, 12:00:00 AM UTC – December 1, 2020, 10:05:00 AM UTC"

      iex> Cldr.Interval.to_string! ~U[2020-01-01 00:00:00.0Z], ~U[2020-01-01 10:05:00.0Z], MyApp.Cldr,
      ...> format: :long
      "January 1, 2020, 12:00:00 AM UTC – 10:05:00 AM UTC"

  """
  @spec to_string!(datetime, datetime, Cldr.backend(), Keyword.t()) :: String.t() | no_return()

  def to_string!(from, to, backend, options \\ []) do
    case to_string(from, to, backend, options) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end
end
