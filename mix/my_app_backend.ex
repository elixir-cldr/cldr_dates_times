defmodule MyApp.Cldr do
  use Cldr, locales: ["en", "fr"], providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end