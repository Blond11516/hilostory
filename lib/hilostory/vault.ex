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
          tag: "AES.GCM.V1",
          key: :hilostory |> Application.get_env(:hilo_tokens_encryption_key) |> Base.decode64!(),
          iv_length: 12
        }
      )

    {:ok, config}
  end
end
