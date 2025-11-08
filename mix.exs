defmodule Hilostory.MixProject do
  use Mix.Project

  def project do
    [
      app: :hilostory,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
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
      {:bandit, "1.8.0"},
      {:castore, "1.0.16"},
      {:cloak, "1.1.4"},
      {:cloak_ecto, "1.3.0"},
      {:ecto_sql, "3.13.2"},
      {:esbuild, "0.10.0", runtime: Mix.env() == :dev},
      {:finch, "0.20.0"},
      {:joken, "2.6.2"},
      {:joken_jwks, "1.7.0"},
      {:phoenix, "1.8.1"},
      {:phoenix_ecto, "4.7.0"},
      {:phoenix_html, "4.3.0"},
      {:phoenix_live_dashboard, "0.8.7"},
      {:phoenix_live_view, "1.1.17"},
      {:postgrex, "0.21.1"},
      {:req, "0.5.15"},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.3.0"},
      {:tower_sentry, "0.3.5"},
      {:timescale, "0.1.1"},
      {:typed_struct, "0.3.0"},
      {:tz, "0.28.1"},
      {:websockex, "0.4.3"},
      {:zoi, "0.9.1"},
      {:phoenix_live_reload, "1.6.1", only: :dev},
      {:igniter, "0.7.0", only: :dev},
      {:styler, "1.9.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.7", only: [:dev, :test], runtime: false},
      {:lazy_html, "0.1.8", only: :test}
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
      "assets.setup": ["esbuild.install --if-missing", "cmd --cd assets bun install"],
      "assets.build": ["esbuild hilostory"],
      "assets.deploy": [
        "esbuild hilostory --minify",
        "phx.digest"
      ]
    ]
  end
end
