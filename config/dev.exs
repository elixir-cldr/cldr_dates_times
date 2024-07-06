import Config

config :ex_cldr,
  default_locale: "en",
  default_backend: MyApp.Cldr

config :elixir, :time_zone_database, Tz.TimeZoneDatabase
