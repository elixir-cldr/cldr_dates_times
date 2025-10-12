defmodule Cldr.DateTIme.Backend.Test do
  use ExUnit.Case

  test "Formatting via a backend when there is no default backend" do
    default_backend = Application.get_env(:ex_cldr, :default_backend)
    Application.put_env(:ex_cldr, :default_backend, nil)
    assert match?({:ok, _now}, MyApp.Cldr.DateTime.to_string(DateTime.utc_now()))
    assert match?({:ok, _now}, MyApp.Cldr.Date.to_string(Date.utc_today()))
    assert match?({:ok, _now}, MyApp.Cldr.Time.to_string(DateTime.utc_now()))
    Application.put_env(:ex_cldr, :default_backend, default_backend)
  end
end