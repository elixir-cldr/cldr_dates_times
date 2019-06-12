defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "af", "ja", "de"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
