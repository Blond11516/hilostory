defmodule Hilostory.Infrastructure.Hilo.AuthorizationClient do
  @moduledoc false
  @hilo_login_base_url "https://connexion.hiloenergie.com"
  @hilo_oauth_path "/hilodirectoryb2c.onmicrosoft.com/B2C_1A_SIGN_IN/oauth2/v2.0"
  @home_assistant_redirect_uri "https://my.home-assistant.io/redirect/oauth"
  @hilo_client_id "1ca9f585-4a55-4085-8e30-9746a65fa561"

  def fetch_access_token(authorization_code, pkce_verifier)
      when is_binary(authorization_code) and is_binary(pkce_verifier) do
    token_uri = build_hilo_token_uri(authorization_code, pkce_verifier)

    case Req.get(token_uri) do
      {:ok, resp} -> {:ok, parse_access_token_response(resp.body)}
      error -> error
    end
  end

  def refresh_access_token(refresh_token) when is_binary(refresh_token) do
    uri = build_hilo_refresh_uri(refresh_token)

    case Req.get(uri) do
      {:ok, resp} -> {:ok, parse_access_token_response(resp.body)}
      error -> error
    end
  end

  def build_hilo_authorize_uri(state, pkce_code, nonce)
      when is_binary(state) and is_binary(pkce_code) and is_binary(nonce) do
    build_hilo_oauth_uri(
      :authorize,
      %{
        "response_type" => "code",
        "scope" => "openid https://HiloDirectoryB2C.onmicrosoft.com/hiloapis/user_impersonation offline_access",
        "client_id" => @hilo_client_id,
        "state" => state,
        "redirect_uri" => @home_assistant_redirect_uri,
        "code_challenge" => pkce_code,
        "code_challenge_method" => "S256",
        "nonce" => nonce,
        "ui_locales" => "fr"
      }
    )
  end

  defp parse_access_token_response(body) when is_map(body) do
    %{
      "access_token" => access_token,
      "expires_in" => _expires_in,
      "expires_on" => _expires_on,
      "id_token" => id_token,
      "id_token_expires_in" => _id_token_expires_in,
      "not_before" => _not_before,
      "profile_info" => _profile_info,
      "refresh_token" => refresh_token,
      "refresh_token_expires_in" => refresh_token_expires_in,
      "resource" => _resource,
      "scope" => _scope,
      "token_type" => _token_type
    } = body

    %{
      access_token: access_token,
      refresh_token: refresh_token,
      refresh_token_expires_in: refresh_token_expires_in,
      id_token: id_token
    }
  end

  defp build_hilo_token_uri(authorization_code, pkce_verifier)
       when is_binary(authorization_code) and is_binary(pkce_verifier) do
    build_hilo_oauth_uri(
      :token,
      %{
        "client_id" => @hilo_client_id,
        "grant_type" => "authorization_code",
        "redirect_uri" => @home_assistant_redirect_uri,
        "code" => authorization_code,
        "code_verifier" => pkce_verifier
      }
    )
  end

  defp build_hilo_refresh_uri(refresh_token) when is_binary(refresh_token) do
    build_hilo_oauth_uri(
      :token,
      %{
        "client_id" => @hilo_client_id,
        "grant_type" => "refresh_token",
        "redirect_uri" => @home_assistant_redirect_uri,
        "refresh_token" => refresh_token
      }
    )
  end

  defp build_hilo_oauth_uri(endpoint, query_params) when endpoint in [:authorize, :token] and is_map(query_params) do
    @hilo_login_base_url
    |> URI.new!()
    |> URI.append_path(@hilo_oauth_path)
    |> URI.append_path("/" <> Atom.to_string(endpoint))
    |> URI.append_query(URI.encode_query(query_params))
    |> URI.to_string()
  end
end
