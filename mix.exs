defmodule Hilostory.MixProject do
  use Mix.Project

  def project do
    [
      app: :hilostory,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Hilostory.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "1.6.8"},
      {:castore, "1.0.12"},
      {:cloak, "1.1.4"},
      {:cloak_ecto, "1.3.0"},
      {:ecto_sql, "3.12.1"},
      {:esbuild, "0.9.0", runtime: Mix.env() == :dev},
      {:finch, "0.19.0"},
      {:joken, "2.6.2"},
      {:joken_jwks, "1.7.0"},
      {:phoenix, "1.7.20"},
      {:phoenix_ecto, "4.6.3"},
      {:phoenix_html, "4.2.1"},
      {:phoenix_live_dashboard, "0.8.6"},
      {:phoenix_live_view, "1.0.5"},
      {:postgrex, "0.20.0"},
      {:recase, "0.8.1"},
      {:req, "0.5.8"},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.1.0"},
      {:tower_sentry, "0.3.3"},
      {:timescale, "0.1.1"},
      {:typed_struct, "0.3.0"},
      {:tz, "0.28.1"},
      {:websockex, "0.4.3"},
      {:phoenix_live_reload, "1.5.3", only: :dev},
      {:igniter, "0.5.32", only: :dev},
      {:styler, "1.4.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.5", only: [:dev, :test], runtime: false},
      {:floki, "0.37.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["esbuild.install --if-missing", "cmd cd assets && bun install"],
      "assets.build": ["esbuild hilostory"],
      "assets.deploy": [
        "esbuild hilostory --minify",
        "phx.digest"
      ]
    ]
  end
end
