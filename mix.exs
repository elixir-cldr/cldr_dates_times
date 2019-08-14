defmodule CldrDatesTimes.Mixfile do
  use Mix.Project

  @version "2.1.2"

  def project do
    [
      app: :ex_cldr_dates_times,
      version: @version,
      name: "Cldr Dates & Times",
      source_url: "https://github.com/elixir-cldr/cldr_dates_times",
      docs: docs(),
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp description do
    """
    Date, Time and DateTime localization and formatting functions for the Common Locale Data Repository (CLDR).
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      logo: "logo.png",
      groups_for_modules: groups_for_modules(),
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end

  defp groups_for_modules do
    [
      Helpers: [
        Cldr.DateTime.Compiler,
        Cldr.DateTime.Format,
        Cldr.DateTime.Formatter,
        Cldr.DateTime.Timezone
      ]
    ]
  end

  defp deps do
    [
      {:ex_cldr, "~> 2.7"},
      {:ex_cldr_numbers, "~> 2.6"},
      {:ex_cldr_calendars, "~> 1.0"},
      {:ex_doc, "~> 0.18", optional: true, only: [:dev, :release]},
      {:jason, "~> 1.0", optional: true},
      {:benchee, "~> 1.0", optional: true, only: :dev},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib",
        "src/datetime_format_lexer.xrl",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_dates_times",
      "Changelog" =>
        "https://github.com/elixir-cldr/cldr_dates_times/blob/v#{@version}/CHANGELOG.md",
      "Readme" => "https://github.com/elixir-cldr/cldr_dates_times/blob/v#{@version}/README.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
