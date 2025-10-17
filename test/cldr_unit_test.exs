defmodule DateTime.CldrUnitTest do
  use ExUnit.Case, async: true

  @maybe_incorrect_test_result [47, 48, 51, 52, 55, 56, 59, 60]

  for test <- Cldr.DateTime.TestData.parse(),
      test.calendar == :gregorian, test.index not in @maybe_incorrect_test_result do
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
