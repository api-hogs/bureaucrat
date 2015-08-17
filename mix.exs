defmodule Bureaucrat.Mixfile do
  use Mix.Project

  def project do
    [app: :bureaucrat,
     version: "0.0.2",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
     {:plug, "~> 0.14 or ~> 1.0"},
     {:poison, github: "devinus/poison", branch: "master"}
    ]
  end
end
