defmodule Hilostory.Repo do
  use Ecto.Repo,
    otp_app: :hilostory,
    adapter: Ecto.Adapters.Postgres
end
