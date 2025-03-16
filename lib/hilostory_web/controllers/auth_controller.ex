defmodule HilostoryWeb.AuthController do
  use HilostoryWeb, :controller

  alias Hilostory.Infrastructure.Hilo.AuthorizationClient
  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Joken.HiloToken
  alias Hilostory.TokenManager
  alias Hilostory.WebsocketStarter

  def login(conn, _params) do
    pkce_verifier = generate_pkce_verifier()
    pkce_code = generate_pkce_code(pkce_verifier)
    nonce = generate_nonce()
    state = generate_state()

    authorization_uri = AuthorizationClient.build_hilo_authorize_uri(state, pkce_code, nonce)

    conn
    |> fetch_session()
    |> put_session(:state, state)
    |> put_session(:pkce_verifier, pkce_verifier)
    |> put_session(:nonce, nonce)
    |> redirect(external: authorization_uri)
  end

  def callback(conn, params) do
    conn = conn |> fetch_session() |> fetch_flash()

    conn =
      with {:ok, authorization_code} <- Map.fetch(params, "code"),
           {:ok, state} <- Map.fetch(params, "state"),
           {conn, persisted_state} when is_binary(persisted_state) <-
             get_and_delete_session(conn, :state),
           {conn, pkce_verifier} when is_binary(pkce_verifier) <-
             get_and_delete_session(conn, :pkce_verifier),
           {conn, nonce} when is_binary(nonce) <- get_and_delete_session(conn, :nonce),
           ^persisted_state <- state,
           {:ok, tokens} =
             AuthorizationClient.fetch_access_token(authorization_code, pkce_verifier),
           :ok <- verify_nonce(tokens.id_token, nonce),
           refresh_token_expires_at =
             HiloToken.calculate_refresh_token_expiration(tokens.refresh_token_expires_in),
           {:ok, _} <-
             OauthTokensRepository.upsert(
               tokens.access_token,
               tokens.refresh_token,
               refresh_token_expires_at
             ),
           :ok <- WebsocketStarter.start_websocket(),
           :ok <- TokenManager.start_loop() do
        conn
      else
        {:error, e} -> put_flash(conn, :error, "Authentication failed: " <> inspect(e))
        e -> put_flash(conn, :error, "Authentication failed: " <> inspect(e))
      end

    redirect(conn, to: ~p"/login")
  end

  defp verify_nonce(id_token, expected_nonce) when is_binary(id_token) and is_binary(expected_nonce) do
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

  defp hash(blob) when is_binary(blob), do: :crypto.hash(:sha256, blob)
end
