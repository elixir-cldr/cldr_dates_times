if Version.match?(System.version, "~> 1.10") do
  nil
else
  ExUnit.configure(exclude: :elixir_1_10)
end

ExUnit.start(trace: "--trace" in System.argv(), timeout: 220_000)
