# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cloak, json_library: JSON

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.12",
  hilostory: [
    args:
      ~w(ts/app.ts --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configures the endpoint
config :hilostory, HilostoryWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HilostoryWeb.ErrorHTML, json: HilostoryWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Hilostory.PubSub,
  live_view: [signing_salt: "LhqlKPMy"]

config :hilostory,
  ecto_repos: [Hilostory.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  env: Mix.env()

# Configures Elixir's Logger
config :logger, :console,
  utc_log: true,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use the JSON module for JSON parsing
config :phoenix, :json_library, JSON

config :postgrex, json_librar: JSON

config :sentry,
  client: Hilostory.Sentry.FinchClient,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  release: "git" |> System.cmd(["rev-parse", "HEAD"]) |> elem(0) |> String.trim()

config :tesla, JokenJwks.HttpFetcher, adapter: {Tesla.Adapter.Finch, name: :joken_jwks_client}

config :tz, reject_periods_before_year: 2024

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
