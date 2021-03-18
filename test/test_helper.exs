cond do
  Version.match?(System.version, "~> 1.10") ->
    nil
  Version.match?(System.version, "~> 1.9")
    ExUnit.configure(exclude: :elixir_1_10)
  true ->
    ExUnit.configure(exclude: [:elixir_1_9, :elixir_1_10])
end

ExUnit.start(trace: "--trace" in System.argv(), timeout: 220_000)
