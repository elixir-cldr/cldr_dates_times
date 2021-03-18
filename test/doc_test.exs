defmodule Cldr.DateTime.Test do
  use ExUnit.Case
  doctest Cldr.DateTime.Relative
  doctest Cldr.DateTime.Compiler
  doctest Cldr.DateTime.Formatter
  doctest Cldr.DateTime.Format
  doctest Cldr.DateTime
  doctest Cldr.Date
  doctest Cldr.Time

  if Version.match?(System.version, "~> 1.9") do
    doctest Cldr.Interval
    doctest Cldr.DateTime.Interval
    doctest Cldr.Date.Interval
    doctest Cldr.Time.Interval

    doctest MyApp.Cldr.Date
    doctest MyApp.Cldr.Time
    doctest MyApp.Cldr.DateTime
    doctest MyApp.Cldr.DateTime.Relative

    doctest MyApp.Cldr.Interval
    doctest MyApp.Cldr.DateTime.Interval
    doctest MyApp.Cldr.Date.Interval
    doctest MyApp.Cldr.Time.Interval
  end
end
