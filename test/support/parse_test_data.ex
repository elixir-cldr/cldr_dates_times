defmodule Cldr.DateTime.TestData do
  @path "test/data/date_time_formatting.json"

  def parse do
    @path
    |> File.read!()
    |> Cldr.Config.json_library().decode!()
    |> Enum.with_index(&format_test/2)
  end

  @atomize_values [:calendar, :time_format, :date_format, :date_time_format_type, :style]

  def format_test(test, index) do
    test
    |> Cldr.Map.rename_keys("timeLength", "time_format")
    |> Cldr.Map.rename_keys("dateLength", "date_format")
    |> Cldr.Map.rename_keys("semanticSkeleton", "semantic_skeleton")
    |> Cldr.Map.rename_keys("semanticSkeletonLength", "semantic_skeleton_length")
    |> Cldr.Map.rename_keys("classicalSkeleton", "skeleton")
    |> Cldr.Map.rename_keys("yearStyle", "year_style")
    |> Cldr.Map.rename_keys("zoneStyle", "zone_style")
    |> Cldr.Map.rename_keys("hourCycle", "hour_cycle")
    |> Cldr.Map.rename_keys("dateTimeFormatType", "style")
    |> Cldr.Map.atomize_keys()
    |> Cldr.Map.atomize_values(only: @atomize_values)
    |> maybe_atomize_skeleton()
    |> Map.put(:index, index + 1)
    |> parse_input()
    |> determine_test_module()
    |> ensure_style_for_date_time()
  end

  defp maybe_atomize_skeleton(%{skeleton: skeleton} = test) do
    if all_one_field?(skeleton) do
      test
    else
      Map.put(test, :skeleton, String.to_atom(skeleton))
    end
  end

  defp maybe_atomize_skeleton(test) do
    test
  end

  defp all_one_field?(skeleton) do
    field_list =
      skeleton
      |> String.graphemes()
      |> Enum.chunk_by(&(&1))

    length(field_list) == 1
  end

  defp ensure_style_for_date_time(%{test_module: Cldr.DateTime} = test) do
    Map.put_new(test, :style, :at)
  end

  defp ensure_style_for_date_time(test) do
    test
  end

  defp parse_input(test) do
    case test.input do
      <<datetime::binary-19, "Z[", rest::binary>> ->
        timezone = String.trim_trailing(rest, "]")
        datetime = datetime <> "Z"
        Map.put(test, :input, parse_date(datetime, timezone))

      <<datetime::binary-16, "Z[", rest::binary>> ->
        timezone = String.trim_trailing(rest, "]")
        datetime = datetime <> ":00" <> "Z"
        Map.put(test, :input, parse_date(datetime, timezone))

      <<datetime::binary-16, "+", offset::binary-5, "[", rest::binary>> ->
        timezone = String.trim_trailing(rest, "]")
        datetime = datetime <> ":00" <> "+" <> offset
        Map.put(test, :input, parse_date(datetime, timezone))

      <<datetime::binary-19, "+", offset::binary-5, "[", rest::binary>> ->
        timezone = String.trim_trailing(rest, "]")
        datetime = datetime <> "+" <> offset
        Map.put(test, :input, parse_date(datetime, timezone))
    end
  end

  def parse_date(datetime, timezone) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime)
    {:ok, datetime} = DateTime.shift_zone(datetime, timezone)
    datetime
  end

  defp determine_test_module(%{skeleton: _} = test) do
    Map.put(test, :test_module, Cldr.DateTime)
  end

  defp determine_test_module(%{time_format: _, date_format: _} = test) do
    Map.put(test, :test_module, Cldr.DateTime)
  end

  defp determine_test_module(%{date_format: _} = test) do
    Map.put(test, :test_module, Cldr.Date)
  end

  defp determine_test_module(%{time_format: _} = test) do
    Map.put(test, :test_module, Cldr.Time)
  end

  def run_tests do
    tests =
      parse()
      |> Enum.filter(&(&1.calendar == :gregorian))

    test_count = Enum.count(tests)
    IO.puts("Running #{test_count} tests")

    Enum.map(tests, fn test ->
      IO.puts("Test #{test.index}")

      case test.test_module do
        Cldr.Date ->
          {:ok, result} =
            Cldr.Date.to_string(test.input, format: test.date_format, locale: test.locale)

          if result != test.expected do
            IO.puts("Error in test #{test.index}")
            IO.puts("  Expected: #{test.expected}")
            IO.puts("  Result: #{result}")
          end

        Cldr.Time ->
          {:ok, result} =
            Cldr.Time.to_string(test.input, format: test.time_format, locale: test.locale)

          if result != test.expected do
            IO.puts("Error in test #{test.index}")
            IO.puts("  Expected: #{test.expected}")
            IO.puts("  Result: #{result}")
          end

        _other ->
          nil
      end
    end)

    :done
  end
end
