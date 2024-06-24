defmodule Cldr.DatesTimes.Dialyzer do
  @moduledoc """
  Functions just here to exercise dialyzer.

  This module is not included in the hex package.

  """
  def backend_formats do
    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.date_time_formats("en")
    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.date_formats("en")
    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.time_formats("en")

    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.date_time_formats(:en)
    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.date_formats(:en)
    {:ok, %{medium: _format_dt}} = MyApp.Cldr.DateTime.Format.time_formats(:en)
  end

  def format do
    _ = Cldr.DateTime.Format.calendars_for(:en, MyApp.Cldr)
    _ = Cldr.DateTime.Format.calendars_for("en", MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.calendars_for("en")

    _ = Cldr.DateTime.Format.gmt_format(:en, MyApp.Cldr)
    _ = Cldr.DateTime.Format.gmt_format("en", MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.gmt_format("en")

    _ = Cldr.DateTime.Format.gmt_zero_format(:en, MyApp.Cldr)
    _ = Cldr.DateTime.Format.gmt_zero_format("en", MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.gmt_zero_format("en")

    _ = Cldr.DateTime.Format.hour_format(:en, MyApp.Cldr)
    _ = Cldr.DateTime.Format.hour_format("en", MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.hour_format("en")

    _ = Cldr.DateTime.Format.date_formats(:en, :buddhist, MyApp.Cldr)
    _ = Cldr.DateTime.Format.date_formats("en", :buddhist, MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.date_formats("en", :buddhist)

    _ = Cldr.DateTime.Format.time_formats(:en, :buddhist)
    _ = Cldr.DateTime.Format.time_formats("en", :buddhist)
    _ = MyApp.Cldr.DateTime.Format.time_formats("en")

    _ = Cldr.DateTime.Format.date_formats(:en, :buddhist)
    _ = Cldr.DateTime.Format.date_formats("en", :buddhist)
    _ = MyApp.Cldr.DateTime.Format.date_formats("en", :buddhist)

    _ = Cldr.DateTime.Format.date_time_formats(:en, :buddhist)
    _ = Cldr.DateTime.Format.date_time_formats("en", :buddhist)
    _ = MyApp.Cldr.DateTime.Format.date_formats("en", :buddhist)

    _ = Cldr.DateTime.Format.date_time_available_formats(:en)
    _ = Cldr.DateTime.Format.date_time_available_formats("en")
    _ = MyApp.Cldr.DateTime.Format.date_time_available_formats("en")

    _ = Cldr.DateTime.Format.interval_formats(:en, :gregorian, MyApp.Cldr)
    _ = Cldr.DateTime.Format.interval_formats("en", :gregorian, MyApp.Cldr)
    _ = MyApp.Cldr.DateTime.Format.date_time_interval_formats("en", :gregorian)

    _ = Cldr.DateTime.Format.common_date_time_format_names()
  end
end
