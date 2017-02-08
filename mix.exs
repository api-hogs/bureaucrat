defmodule Bureaucrat.Mixfile do
  use Mix.Project

  def project do
    [app: :bureaucrat,
     version: "0.1.4",
     elixir: "~> 1.0",
     description: "Generate Phoenix API documentation from tests",
     deps: deps(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [registered: [Bureaucrat.Recorder],
      mod: {Bureaucrat, []},
      env: [
        writer: Bureaucrat.MarkdownWriter,
        default_path: "web/controllers/README.md",
        paths: [],
        env_var: "DOC"
      ]]
  end

  defp deps do
    [
     {:plug, "~> 1.0"},
     {:poison, "~> 3.0"}
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md UNLICENSE),
      maintainers: ["Roman Kuznietsov"],
      licenses: ["Unlicense"],
      links: %{"GitHub" => "https://github.com/api-hogs/bureaucrat"}
    ]
  end
end
