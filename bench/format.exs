now = DateTime.utc_now()

Benchee.run(
  %{
    "Datetime.to_string" => fn -> Cldr.DateTime.to_string now end,
  },
  time: 10,
  memory_time: 2
)