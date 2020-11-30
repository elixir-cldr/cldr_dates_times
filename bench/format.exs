date = DateTime.utc_now

Benchee.run(
  %{
    "Cldr.DateTime.to_string" => fn -> Cldr.DateTime.to_string date end,
  },
  time: 10,
  memory_time: 2
)