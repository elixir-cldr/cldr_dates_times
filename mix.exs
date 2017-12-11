defmodule CldrDatesTimes.Mixfile do
  use Mix.Project

  @version "1.0.0-rc.1"

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
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:ex_cldr, "~> 1.0"},
      {:ex_cldr_numbers, "~> 1.0"},
      {:ex_doc, "~> 0.18", optional: true, only: :dev},
      {:stream_data, "~> 0.4", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib", "src", "config", "mix.exs", "README*", "CHANGELOG*", "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub"    => "https://github.com/kipcole9/cldr_dates_times",
      "Changelog" => "https://github.com/kipcole9/cldr_dates_times/blob/v#{@version}/CHANGELOG.md"
    }
  end

end
