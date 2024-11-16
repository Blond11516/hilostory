defmodule HilostoryWeb.AuthController do
  use HilostoryWeb, :controller

  alias Hilostory.Joken.HiloToken
  alias Hilostory.Infrastructure.OauthTokensRepository

  @hilo_login_base_url "https://connexion.hiloenergie.com"
  @hilo_oauth_path "/hilodirectoryb2c.onmicrosoft.com/B2C_1A_SIGN_IN/oauth2/v2.0"
  @home_assistant_redirect_uri "https://my.home-assistant.io/redirect/oauth"
  @hilo_client_id "1ca9f585-4a55-4085-8e30-9746a65fa561"

  def login(conn, _params) do
    pkce_verifier = generate_pkce_verifier()
    pkce_code = generate_pkce_code(pkce_verifier)
    nonce = generate_nonce()
    state = generate_state()

    authorization_uri = build_hilo_authorize_uri(state, pkce_code, nonce)

    conn
    |> fetch_session()
    |> put_session(:state, state)
    |> put_session(:pkce_verifier, pkce_verifier)
    |> put_session(:nonce, nonce)
    |> redirect(external: authorization_uri)
  end

  def callback(conn, params) do
    conn = conn |> fetch_session() |> fetch_flash()

    with {:ok, authorization_code} <- Map.fetch(params, "code"),
         {:ok, state} <- Map.fetch(params, "state"),
         {conn, persisted_state} when is_binary(persisted_state) <-
           get_and_delete_session(conn, :state),
         {conn, pkce_verifier} when is_binary(pkce_verifier) <-
           get_and_delete_session(conn, :pkce_verifier),
         {conn, nonce} when is_binary(nonce) <- get_and_delete_session(conn, :nonce),
         ^persisted_state <- state,
         {:ok, {access_token, refresh_token, id_token}} =
           fetch_tokens(authorization_code, pkce_verifier),
         :ok <- verify_nonce(id_token, nonce),
         {:ok, _} <- OauthTokensRepository.upsert(access_token, refresh_token) do
      conn
    else
      e -> put_flash(conn, :error, "Authentication failed: " <> inspect(e))
    end
    |> redirect(to: ~p"/login")
  end

  defp verify_nonce(id_token, expected_nonce)
       when is_binary(id_token) and is_binary(expected_nonce) do
    with {:ok, %{"nonce" => nonce}} <- HiloToken.verify_and_validate(id_token),
         ^expected_nonce <- nonce do
      :ok
    end
  end

  defp urlencode(binary) when is_binary(binary), do: Base.url_encode64(binary, padding: false)

  defp get_and_delete_session(%Plug.Conn{} = conn, key) when is_atom(key) do
    value = get_session(conn, key)
    conn = delete_session(conn, key)
    {conn, value}
  end

  defp generate_pkce_verifier do
    96
    |> :crypto.strong_rand_bytes()
    |> urlencode()
  end

  defp generate_pkce_code(verifier) when is_binary(verifier) do
    verifier
    |> hash()
    |> urlencode()
  end

  defp generate_nonce do
    32
    |> :crypto.strong_rand_bytes()
    |> hash()
    |> urlencode()
  end

  defp generate_state do
    16
    |> :crypto.strong_rand_bytes()
    |> urlencode()
  end

  defp fetch_tokens(authorization_code, pkce_verifier)
       when is_binary(authorization_code) and is_binary(pkce_verifier) do
    token_uri = build_hilo_token_uri(authorization_code, pkce_verifier)

    with {:ok, response} <- Req.get(token_uri) do
      %{
        "access_token" => access_token,
        "expires_in" => _expires_in,
        "expires_on" => _expires_on,
        "id_token" => id_token,
        "id_token_expires_in" => _id_token_expires_in,
        "not_before" => _not_before,
        "profile_info" => _profile_info,
        "refresh_token" => refresh_token,
        "refresh_token_expires_in" => _refresh_token_expires_in,
        "resource" => _resource,
        "scope" => _scope,
        "token_type" => _token_type
      } = response.body

      {:ok, {access_token, refresh_token, id_token}}
    end
  end

  defp build_hilo_authorize_uri(state, pkce_code, nonce)
       when is_binary(state) and is_binary(pkce_code) and is_binary(nonce) do
    build_hilo_oauth_uri(
      :authorize,
      %{
        "response_type" => "code",
        "scope" =>
          "openid https://HiloDirectoryB2C.onmicrosoft.com/hiloapis/user_impersonation offline_access",
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

  defp build_hilo_oauth_uri(endpoint, query_params)
       when endpoint in [:authorize, :token] and is_map(query_params) do
    @hilo_login_base_url
    |> URI.new!()
    |> URI.append_path(@hilo_oauth_path)
    |> URI.append_path("/" <> Atom.to_string(endpoint))
    |> URI.append_query(URI.encode_query(query_params))
    |> URI.to_string()
  end

  defp hash(blob) when is_binary(blob), do: :crypto.hash(:sha256, blob)
end
