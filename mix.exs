defmodule CldrDatesTimes.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :ex_cldr_dates_times,
      version: @version,
      name: "Cldr Dates Times",
      source_url: "https://github.com/kipcole9/cldr_dates_times",
      docs: docs(),
      elixir: "~> 1.5",
      description: description(),
      package: package(),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  defp description do
    """
    Dates, Times and DateTimes localization and formatting functions for the Common Locale Data Repository (CLDR).
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
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp deps do
    [
      {:ex_cldr, "~> 0.8.1"},
      {:ex_cldr_numbers, "~> 0.2.0"},
      {:ex_doc, ">= 0.18.1", optional: true, only: :dev},
      {:stream_data, ">= 0.3.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib", "config", "mix.exs", "README*", "CHANGELOG*", "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub"    => "https://github.com/kipcole9/cldr_dates_times",
      "Readme"    => "https://github.com/kipcole9/cldr_dates_times/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/kipcole9/cldr_dates_times/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev),  do: ["lib", "mix"]
  defp elixirc_paths(_),     do: ["lib"]

end
