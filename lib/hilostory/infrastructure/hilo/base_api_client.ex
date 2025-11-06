defmodule Hilostory.Infrastructure.Hilo.BaseApiClient do
  @moduledoc false
  require Logger

  @hilo_api_base_url URI.new!("https://api.hiloenergie.com")

  @subscription_key "20eeaedcb86945afa3fe792cea89b8bf"

  @spec get(
          nonempty_binary(),
          nonempty_binary(),
          nonempty_binary(),
          module()
        ) :: {:error, term()} | {:ok, Req.Response.t()}
  def get(api_path_prefix, endpoint, access_token, model_module)
      when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and is_atom(model_module) do
    api_path_prefix
    |> prepare_request(endpoint, access_token, model_module)
    |> Req.get()
  end

  @spec post(
          nonempty_binary(),
          nonempty_binary(),
          nonempty_binary(),
          module()
        ) :: {:error, term()} | {:ok, Req.Response.t()}
  def post(api_path_prefix, endpoint, access_token, model_module)
      when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and is_atom(model_module) do
    api_path_prefix
    |> prepare_request(endpoint, access_token, model_module)
    |> Req.post(body: "")
  end

  @spec post(
          nonempty_binary(),
          nonempty_binary(),
          nonempty_binary(),
          module()
        ) :: Req.Request.t()
  defp prepare_request(api_path_prefix, endpoint, access_token, model_module)
       when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and is_atom(model_module) do
    uri = get_uri(api_path_prefix, endpoint)

    Logger.debug("Send GET request to #{uri}")

    [
      url: uri,
      auth: {:bearer, access_token},
      headers: %{
        "content-type" => "application/json; charset=utf-8",
        "ocp-apim-subscription-key" => @subscription_key
      }
    ]
    |> Req.new()
    |> Req.Request.append_response_steps(
      parse_body: fn {request, response} ->
        parsed_body =
          if response.status == 200 do
            case response.body do
              body when is_list(body) -> Enum.map(body, &Zoi.parse!(model_module.schema(), &1))
              body -> Zoi.parse!(model_module.schema(), body)
            end
          else
            response.body
          end

        {request, %{response | body: parsed_body}}
      end
    )
  end

  @spec get_uri(nonempty_binary(), nonempty_binary()) :: nonempty_binary()
  defp get_uri(api_path_prefix, endpoint) do
    @hilo_api_base_url
    |> URI.append_path(api_path_prefix)
    |> URI.append_path(endpoint)
    |> URI.to_string()
  end
end
