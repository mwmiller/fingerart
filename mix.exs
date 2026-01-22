defmodule Fingerart.MixProject do
  use Mix.Project

  def project do
    [
      app: :fingerart,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Fingerart",
      source_url: "https://github.com/mwmiller/fingerart"
    ]
  end

  defp description do
    "Generate OpenSSH-style fingerprint random art (The Drunken Bishop algorithm) in Elixir."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mwmiller/fingerart"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
