defmodule Cldr.DateTime.Interval.Backend do
  @moduledoc false

  def define_date_time_interval_module(config) do
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [config: config, backend: backend] do
      defmodule DateTime.Interval do
        @moduledoc """
        Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
        shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
        to take a start and end date, time or datetime plus a formatting pattern
        and use that information to produce a localized format.

        See `Cldr.Interval.to_string/3` and `Cldr.DateTime.Interval.to_string/3`

        """
        if Cldr.Code.ensure_compiled?(CalendarInterval) do
          def to_string(%CalendarInterval{} = interval, options) do
            Cldr.DateTime.Interval.to_string(interval, unquote(backend), options)
          end
        end

        def to_string(from, to) do
          Cldr.DateTime.Interval.to_string(from, to, unquote(backend))
        end

        def to_string(from, to, options) do
          if Cldr.Code.ensure_compiled?(CalendarInterval) do
            Cldr.DateTime.Interval.to_string(from, to, unquote(backend), options)
          end
        end
      end
    end
  end
end
