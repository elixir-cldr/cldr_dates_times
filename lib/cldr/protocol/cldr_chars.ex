defimpl Cldr.Chars, for: Date do
  def to_string(date) do
    locale = Cldr.get_locale()
    Cldr.Date.to_string!(date, locale.backend, locale: locale)
  end
end

defimpl Cldr.Chars, for: Time do
  def to_string(date) do
    locale = Cldr.get_locale()
    Cldr.Time.to_string!(date, locale.backend, locale: locale)
  end
end

defimpl Cldr.Chars, for: DateTime do
  def to_string(datetime) do
    locale = Cldr.get_locale()
    Cldr.DateTime.to_string!(datetime, locale.backend, locale: locale)
  end
end

defimpl Cldr.Chars, for: NaiveDateTime do
  def to_string(datetime) do
    locale = Cldr.get_locale()
    Cldr.DateTime.to_string!(datetime, locale.backend, locale: locale)
  end
end

defimpl Cldr.Chars, for: Date.Range do
  def to_string(range) do
    locale = Cldr.get_locale()
    Cldr.Date.Interval.to_string!(range, locale.backend, locale: locale)
  end
end

if Cldr.Code.ensure_compiled?(CalendarInterval) do
  defimpl Cldr.Chars, for: CalendarInterval do
    def to_string(interval) do
      locale = Cldr.get_locale()
      Cldr.DateTime.Interval.to_string!(interval, locale.backend, locale: locale)
    end
  end
end
