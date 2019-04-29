defmodule Cldr.DateTime.Backend do
  @moduledoc false

  def define_date_time_modules(config) do
    config = Macro.escape(config)

    quote bind_quoted: [config: config], location: :keep do
      Cldr.DateTime.Format.Backend.define_date_time_format_module(config)
      Cldr.DateTime.Relative.Backend.define_date_time_relative_module(config)
    end
  end
end