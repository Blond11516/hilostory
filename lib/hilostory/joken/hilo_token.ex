defmodule Hilostory.Joken.HiloToken do
  @moduledoc false
  use Joken.Config

  @expected_aud "1ca9f585-4a55-4085-8e30-9746a65fa561"

  add_hook(JokenJwks, strategy: Hilostory.Joken.HiloStrategy)

  @impl Joken.Config
  def token_config do
    add_claim(%{}, "aud", nil, fn aud -> aud == @expected_aud end)
  end

  def calculate_refresh_token_expiration(expires_in) when is_integer(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
end
