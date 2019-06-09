defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "af", "ja"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
