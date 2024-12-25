defmodule Hilostory.WebsocketStarter do
  use Task

  require Logger

  def start_link(_) do
    Task.start_link(__MODULE__, :start_websocket, [])
  end

  def start_websocket() do
    case Hilostory.Infrastructure.OauthTokensRepository.get() do
      nil ->
        Logger.info("Did not find Hilo credentials, will not start websocket.")

      tokens ->
        Logger.info("Found Hilo credentials, starting websocket")
        Hilostory.WebsocketSuperviser.start_websocket(tokens)
    end
  end
end
