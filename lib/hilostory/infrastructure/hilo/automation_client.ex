defmodule Hilostory.Infrastructure.Hilo.AutomationClient do
  @moduledoc false
  alias Hilostory.Infrastructure.Hilo.BaseApiClient
  alias Hilostory.Infrastructure.Hilo.Models.Device
  alias Hilostory.Infrastructure.Hilo.Models.Location

  require Logger

  @path_prefix "/Automation/v1/api"

  @spec list_devices(String.t(), integer()) :: {:error, term()} | {:ok, Req.Response.t()}
  def list_devices(access_token, location_id) when is_binary(access_token) and is_integer(location_id) do
    BaseApiClient.get(
      @path_prefix,
      "/Locations/#{location_id}/Devices",
      access_token,
      Device
    )
  end

  @spec list_locations(String.t()) :: {:error, term()} | {:ok, Req.Response.t()}
  def list_locations(access_token) when is_binary(access_token) do
    BaseApiClient.get(
      @path_prefix,
      "/Locations",
      access_token,
      Location
    )
  end
end
