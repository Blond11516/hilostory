defmodule IexHelpers do
  def access_token() do
    IexAccessTokenStore.get_access_token()
  end
end

defmodule IexAccessTokenStore do
  use GenServer

  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Joken.HiloToken
  alias Hilostory.Schema.OauthTokensSchema

  @dummy_token "eyJhbGciOiJSUzI1NiIsImtpZCI6IklCNnBKQzdSbGhua0tsMkRvaUU2YWhnbEV1QnRlOTBsaUhFZy1WUDdvRUEiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOiI2MDQ5ZjQwNS04Yjc3LTRmYzQtYjFhMC03MjVkZDVhMzQ5ZjEiLCJpc3MiOiJodHRwczovL2Nvbm5leGlvbi5oaWxvZW5lcmdpZS5jb20vZThhZThjNWEtYTA2Ny00NzUzLThkMzQtZWUzNGQzOWYzMzA3L3YyLjAvIiwiZXhwIjoxNzMyNDY4Nzc0LCJuYmYiOjE3MzI0NjUxNzQsInN1YiI6IjRiYWJlZjM0LWUwZDYtNDc4Mi1iNjE2LTZhODYxNWNiNWIzZiIsIm5hbWUiOiJCw6lsYW5nZXIsIEpvYW5pZSIsInVpZCI6IjRiYWJlZjM0LWUwZDYtNDc4Mi1iNjE2LTZhODYxNWNiNWIzZkBIaWxvRGlyZWN0b3J5QjJDLm9ubWljcm9zb2Z0LmNvbSIsImVtYWlsIjoiam9hbmllNzg4QGhvdG1haWwuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvYW5pZSIsImZhbWlseV9uYW1lIjoiQsOpbGFuZ2VyIiwidXJuOmNvbTpoaWxvZW5lcmdpZTpwcm9maWxlOmxvY2F0aW9uX2hpbG9faWQiOlsidXJuOmhpbG86Y3JtOjQ1OTQyNzYtczNoMmw5OjAiXSwidGlkIjoiZThhZThjNWEtYTA2Ny00NzUzLThkMzQtZWUzNGQzOWYzMzA3IiwiaXNGb3Jnb3RQYXNzd29yZCI6ZmFsc2UsImlzU2lnblVwIjpmYWxzZSwibm9uY2UiOiJvRUlhY213MktzYm8xbXl4QkJ5N1RWTzQ2NzItanZaTVJIY2c4NXQ2cUE0Iiwic2NwIjoidXNlcl9pbXBlcnNvbmF0aW9uIiwiYXpwIjoiMWNhOWY1ODUtNGE1NS00MDg1LThlMzAtOTc0NmE2NWZhNTYxIiwidmVyIjoiMS4wIiwiaWF0IjoxNzMyNDY1MTc0fQ.fzQvYhxJIavZHc1rx79UfRfFS3JwttdtO-6M7yhoffUeN3QMTZdaFBQZBgWfC_gzjNCI9CuC_0ZOYKmAWm0oGD_dqeYBqX8JDUGkezWYHYEPgZVhoutb-EPHnpaX3U9fP9rsKmkX3-NOHIoXuEis7Ts8zCpIwurvlyYXpblyZyfnR3KX1jd9TcU1klFBuc7FBTuTcUM7zzNai8LWPpjMwchq4SH-kgHq2HS5wHBvBDaoPf0dySZk3ItI4CD7ufdtmu3LpB_7sZBTO6X846cgWexBTmNbdd0Z6eN8fxZeFJfp9BoNA2VlNzqZckS5XuwJ4TEZhkIki_zNZ9UvGWXqmg"

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_access_token() do
    GenServer.call(__MODULE__, :get_access_token)
  end

  @impl true
  def init(_init_arg) do
    {:ok, nil, {:continue, :load_access_token}}
  end

  @impl true
  def handle_continue(:load_access_token, _state) do
    fn -> nil end
    |> Stream.repeatedly()
    |> Stream.take_while(fn _ ->
      case HiloToken.verify(@dummy_token) do
        {:error, :no_signers_fetched} ->
          Process.sleep(2_000)
          true

        _ ->
          false
      end
    end)
    |> Stream.run()

    {:noreply, update_token()}
  end

  @impl true
  def handle_info(:update_token, _state) do
    {:noreply, update_token()}
  end

  @impl true
  def handle_call(:get_access_token, _from, state) do
    access_token =
      with nil <- state,
           nil <- update_token() do
        raise "No valid access token in the database"
      end

    {:reply, access_token, access_token}
  end

  defp update_token() do
    with %OauthTokensSchema{access_token: access_token} <- OauthTokensRepository.get(),
         {:ok, claims} <- HiloToken.verify(access_token),
         {:ok, expires_at} <- Map.fetch(claims, "exp"),
         expires_at = DateTime.from_unix!(expires_at),
         update_in when update_in > 0 <-
           DateTime.diff(expires_at, DateTime.utc_now(), :millisecond) - 10 do
      Process.send_after(self(), :update_token, update_in)
      access_token
    else
      _error -> nil
    end
  end
end
