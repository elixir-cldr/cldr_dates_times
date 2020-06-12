defmodule Cldr.DateTime.Backend do
  @moduledoc false

  def define_date_time_modules(config) do
    quote location: :keep do
      unquote(Cldr.DateAndTime.Backend.define_backend_modules(config))
      unquote(Cldr.DateTime.Format.Backend.define_date_time_format_module(config))
      unquote(Cldr.DateTime.Formatter.Backend.define_date_time_formatter_module(config))
      unquote(Cldr.DateTime.Relative.Backend.define_date_time_relative_module(config))
      unquote(Cldr.Interval.Backend.define_interval_module(config))
      unquote(Cldr.DateTime.Interval.Backend.define_date_time_interval_module(config))
      unquote(Cldr.Date.Interval.Backend.define_date_interval_module(config))
      unquote(Cldr.Time.Interval.Backend.define_time_interval_module(config))
    end
  end
end
