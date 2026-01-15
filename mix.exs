defmodule ElixirFenwick.MixProject do
  use Mix.Project

  def project do
    [
      app: :fenwick_tree,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/lukaszsamson/fenwick_tree",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.32", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Fenwick (Binary Indexed) tree for prefix sums and point updates."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lukaszsamson/fenwick_tree"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
