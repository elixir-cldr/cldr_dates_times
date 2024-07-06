defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "af", "ja", "de", "pl", "th", "fa", "es", "da"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime],
    precompile_number_formats: ["#,##0"],
    precompile_transliterations: [{:latn, :thai}]
end
