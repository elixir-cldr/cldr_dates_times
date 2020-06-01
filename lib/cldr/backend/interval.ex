defmodule Cldr.DateTime.Interval.Backend do
  @moduledoc false

  def define_date_time_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule DateTime.Interval do
      end

      defmodule Date.Interval do
      end

      defmodule Time.Interval do
      end
    end
  end
end
