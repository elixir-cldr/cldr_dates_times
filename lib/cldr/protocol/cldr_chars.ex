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
