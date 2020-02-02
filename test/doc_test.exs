defmodule Cldr.DateTime.Test do
  use ExUnit.Case
  doctest Cldr.DateTime.Relative
  doctest Cldr.DateTime.Compiler
  doctest Cldr.DateTime.Formatter
  doctest Cldr.DateTime.Format
  doctest Cldr.DateTime
  doctest Cldr.Date
  doctest Cldr.Time

  doctest MyApp.Cldr.Date
  doctest MyApp.Cldr.Time
  doctest MyApp.Cldr.DateTime
end
