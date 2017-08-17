defmodule Doc.Test do
  use ExUnit.Case
  doctest Cldr.DateTime.Relative
  doctest Cldr.DateTime.Compiler
  doctest Cldr.DateTime.Formatter
  doctest Cldr.DateTime
  doctest Cldr.Date
end
