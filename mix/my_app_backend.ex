defmodule MyApp.Cldr do
  use Cldr,
    locales: [
      "en",
      "fr",
      "af",
      "ja",
      "de",
      "pl",
      "th",
      "fa",
      "es",
      "da",
      "he",
      "en-CA",
      "en-AU",
      "en-GB",
      "it",
      "ar"
    ],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Unit, Cldr.List],
    precompile_number_formats: ["#,##0"],
    precompile_transliterations: [{:latn, :thai}]
end
