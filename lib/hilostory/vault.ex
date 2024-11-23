defmodule Hilostory.Vault do
  use Cloak.Vault, otp_app: :hilostory

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1",
          key: "HILO_TOKENS_ENCRYPTION_KEY" |> System.fetch_env!() |> Base.decode64!(),
          iv_length: 12
        }
      )

    {:ok, config}
  end
end
