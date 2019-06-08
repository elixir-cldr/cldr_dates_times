defmodule Cldr.DateTime.Backend do
  @moduledoc false

  def define_date_time_modules(config) do
    quote location: :keep do
      unquote(Cldr.DateTime.Format.Backend.define_date_time_format_module(config))
      unquote(Cldr.DateTime.Formatter.Backend.define_date_time_formatter_module(config))
      unquote(Cldr.DateTime.Relative.Backend.define_date_time_relative_module(config))
    end
  end
end
