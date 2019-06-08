defmodule MyApp.Cldr do
  use Cldr, locales: ["en", "fr", "af"], providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
