defmodule LumaaiEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/vitalis/lumaai_ex"
  def project do
    [
      app: :lumaai_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls.travis": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      config_path: "config/config.exs"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:bypass, "~> 2.1", only: :test},
      {:git_ops, "~> 2.6.1", only: [:dev]},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp description do
    """
    A client library for the Luma Labs API
    """
  end

  defp package do
    [
      name: :lumaai_ex,
      maintainers: ["Vitaly Gorodetsky"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md": [title: "Changelog"]]
    ]
  end
end
