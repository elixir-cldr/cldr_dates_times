defmodule Cldr.DatesTimes.Mixfile do
  use Mix.Project

  @version "2.21.0"

  def project do
    [
      app: :ex_cldr_dates_times,
      version: @version,
      name: "Cldr Dates & Times",
      source_url: "https://github.com/elixir-cldr/cldr_dates_times",
      docs: docs(),
      elixir: "~> 1.12",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:leex, :yecc] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(calendar_interval)a,
        flags: [
          :error_handling,
          :unknown,
          :underspecs,
          :extra_return,
          :missing_return
        ]
      ],
      xref: [exclude: [:eprof]]
    ]
  end

  defp description do
    """
    Date, Time and DateTime localization, internationalization and formatting
    functions using the Common Locale Data Repository (CLDR).
    """
  end

  def application do
    [
      extra_applications: [:logger, :tools]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      logo: "logo.png",
      formatters: ["html"],
      groups_for_modules: groups_for_modules(),
      skip_undefined_reference_warnings_on: ["changelog", "readme", "CHANGELOG.md"]
    ]
  end

  defp groups_for_modules do
    [
      Interval: [
        Cldr.Interval,
        Cldr.Date.Interval,
        Cldr.Time.Interval,
        Cldr.DateTime.Interval
      ],
      Helpers: [
        Cldr.DateTime.Format.Compiler,
        Cldr.DateTime.Format,
        Cldr.DateTime.Formatter,
        Cldr.DateTime.Timezone
      ]
    ]
  end

  defp deps do
    [
      # {:ex_cldr, path: "../cldr", override: true},
      {:ex_cldr, "~> 2.40"},

      {:ex_cldr_calendars, "~> 1.25 or ~> 2.0"},

      {:calendar_interval, "~> 0.2", optional: true},
      {:ex_cldr_units, "~> 3.17", optional: true},
      {:ex_doc, "~> 0.25", optional: true, only: [:dev, :release], runtime: false},
      {:jason, "~> 1.0", optional: true},
      {:tz, "~> 0.26", optional: true},
      {:benchee, "~> 1.0", optional: true, only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", optional: true, only: [:dev, :test], runtime: false},
      {:exprof, "~> 0.2", optional: true, only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "src/date_time_format_lexer.xrl",
        "src/skeleton_tokenizer.xrl",
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
  defp elixirc_paths(:docs), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
