defmodule Hilostory.Joken.HiloStrategy do
  use JokenJwks.DefaultStrategyTemplate

  @hilo_jwks_url "https://connexion.hiloenergie.com/hilodirectoryb2c.onmicrosoft.com/b2c_1a_sign_in/discovery/keys"

  def init_opts(_opts),
    do: [jwks_url: @hilo_jwks_url, first_fetch_sync: false, explicit_alg: "RS256"]
end
