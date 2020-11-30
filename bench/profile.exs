defmodule ProfileRunner do
  import ExProf.Macro

  @doc "analyze with profile macro"
  def do_analyze do
    today = DateTime.utc_now()

    profile do
      Cldr.DateTime.to_string today
    end
  end

  @doc "get analysis records and sum them up"
  def run do
    {records, _block_result} = do_analyze()

    records
    |> Enum.filter(&String.contains?(&1.function, "Cldr.DateTime"))
    |> ExProf.Analyzer.print
  end

end

ProfileRunner.run

#
# Total:                                                                             215  100.00%   328  [      1.53]
# %Prof{
#   calls: 1,
#   function: "'Elixir.Cldr.Number.Formatter.Decimal':add_first_group/3",
#   percent: 0.0,
#   time: 0,
#   us_per_call: 0.0
# }