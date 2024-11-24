defmodule Hilostory.Infrastructure.Hilo.BaseApiClient do
  require Logger

  @hilo_api_base_url URI.new!("https://api.hiloenergie.com")

  @subscription_key "20eeaedcb86945afa3fe792cea89b8bf"

  def get(api_path_prefix, endpoint, access_token, parse_body)
      when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and
             is_function(parse_body) do
    prepare_request(api_path_prefix, endpoint, access_token, parse_body)
    |> Req.get()
  end

  def post(api_path_prefix, endpoint, access_token, parse_body)
      when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and
             is_function(parse_body) do
    prepare_request(api_path_prefix, endpoint, access_token, parse_body)
    |> Req.post(body: "")
  end

  defp prepare_request(api_path_prefix, endpoint, access_token, parse_body)
       when is_binary(api_path_prefix) and is_binary(endpoint) and is_binary(access_token) and
              is_function(parse_body) do
    uri = get_uri(api_path_prefix, endpoint)

    Logger.debug("Send GET request to #{uri}")

    Req.new(
      url: uri,
      auth: {:bearer, access_token},
      headers: %{
        "content-type" => "application/json; charset=utf-8",
        "ocp-apim-subscription-key" => @subscription_key
      }
    )
    |> Req.Request.append_response_steps(
      parse_body: fn {request, response} ->
        parsed_body =
          if response.status == 200 do
            parse_body.(response.body)
          else
            response.body
          end

        {request, %Req.Response{response | body: parsed_body}}
      end
    )
  end

  defp get_uri(api_path_prefix, endpoint) do
    @hilo_api_base_url
    |> URI.append_path(api_path_prefix)
    |> URI.append_path(endpoint)
    |> URI.to_string()
  end
end
