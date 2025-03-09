defmodule Hilostory.Vault do
  @moduledoc false
  use Cloak.Vault, otp_app: :hilostory

  require Logger

  @impl GenServer
  def init(config) do
    Logger.info("Initializing Cloak vault")

    config =
      Keyword.put(config, :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1", key: "HILO_TOKENS_ENCRYPTION_KEY" |> System.fetch_env!() |> Base.decode64!(), iv_length: 12
        }
      )

    {:ok, config}
  end
end
