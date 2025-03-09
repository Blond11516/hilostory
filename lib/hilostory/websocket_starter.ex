defmodule Hilostory.WebsocketStarter do
  alias Hilostory.WebsocketSupervisor
  alias Hilostory.Infrastructure.Hilo.AutomationClient
  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Schema.OauthTokensSchema

  use Task

  require Logger

  def start_link(_) do
    Task.start_link(__MODULE__, :start_websocket, [])
  end

  def start_websocket() do
    Logger.info("Will attempt to start websocket.")

    with %OauthTokensSchema{} = tokens <- OauthTokensRepository.get(),
         {:ok, %{body: [location]}} <- AutomationClient.list_locations(tokens.access_token) do
      Logger.info("Found Hilo credentials and fetched location, starting websocket")
      WebsocketSupervisor.start_websocket(tokens, location)
    else
      error -> Logger.info("Failed to start websocket: #{inspect(error)}")
    end
  end
end
