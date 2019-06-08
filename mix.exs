defmodule CldrDatesTimes.Mixfile do
  use Mix.Project

  @version "2.0.0"

  def project do
    [
      app: :ex_cldr_dates_times,
      version: @version,
      name: "Cldr Dates & Times",
      source_url: "https://github.com/kipcole9/cldr_dates_times",
      docs: docs(),
      elixir: "~> 1.5",
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
      logo: "logo.png"
    ]
  end

  defp deps do
    [
      {:ex_cldr, "~> 2.6"},
      {:ex_cldr_numbers, "~> 2.6"},
      {:ex_cldr_calendars, "~> 0.8"},
      {:ex_doc, "~> 0.18", optional: true, only: [:dev, :release]},
      {:jason, "~> 1.0", optional: true},
      {:benchee, "~> 0.12", optional: true, only: :dev}
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
      "GitHub" => "https://github.com/kipcole9/cldr_dates_times",
      "Changelog" =>
        "https://github.com/kipcole9/cldr_dates_times/blob/v#{@version}/CHANGELOG.md",
      "Readme" => "https://github.com/kipcole9/cldr_dates_times/blob/v#{@version}/README.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
