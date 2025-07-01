import Config

config :ex_cldr,
  default_locale: "en",
  default_backend: MyApp.Cldr

config :ex_unit,
  module_load_timeout: 220_000,
  case_load_timeout: 220_000,
  timeout: 220_000

config :elixir, :time_zone_database, Tz.TimeZoneDatabase
