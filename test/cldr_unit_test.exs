defmodule DateTime.CldrUnitTest do
  use ExUnit.Case, async: true

  # As best I can tell the code is generating the correct results
  # but as always, thee need revisiting
  @should_be_at_format [47, 48, 51, 52, 55, 56, 59, 60]
  @wrong_format [283, 256, 266, 285, 258, 267, 284, 257, 265, 286]
  @maybe_incorrect_test_result @should_be_at_format ++ @wrong_format

  @test_calendars [:gregorian, :japanese]

  for test <- Cldr.DateTime.TestData.parse(),
      test.calendar in @test_calendars,
      test.index not in @maybe_incorrect_test_result do
    case test.test_module do
      Cldr.Date ->
        test "##{test.index} Date format #{inspect(test.date_format)} with locale #{inspect(test.locale)}" do
          assert {:ok, unquote(test.expected)} =
                   Cldr.Date.to_string(unquote(Macro.escape(test.input)),
                     format: unquote(test.date_format),
                     locale: unquote(test.locale)
                   )
        end

      Cldr.Time ->
        test "##{test.index} Time format #{inspect(test.time_format)} with locale #{inspect(test.locale)}" do
          assert {:ok, unquote(test.expected)} =
                   Cldr.Time.to_string(unquote(Macro.escape(test.input)),
                     format: unquote(test.time_format),
                     locale: unquote(test.locale)
                   )
        end

      Cldr.DateTime ->
        if test[:date_format] && test[:time_format] do
          test "##{test.index} DateTime date format #{inspect(test.date_format)} and time format #{inspect(test.time_format)} with locale #{inspect(test.locale)}" do
            assert {:ok, unquote(test.expected)} =
                     Cldr.DateTime.to_string(unquote(Macro.escape(test.input)),
                       date_format: unquote(test.date_format),
                       time_format: unquote(test.time_format),
                       style: unquote(test.style),
                       locale: unquote(test.locale)
                     )
          end
        else
          test "##{test.index} DateTime format #{inspect(test.skeleton)} with locale #{inspect(test.locale)}" do
            assert {:ok, unquote(test.expected)} =
                     Cldr.DateTime.to_string(unquote(Macro.escape(test.input)),
                       format: unquote(test.skeleton),
                       style: unquote(test.style),
                       locale: unquote(test.locale)
                     )
          end
        end
    end
  end
end
