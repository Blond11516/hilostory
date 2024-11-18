defmodule Hilostory.Schema.OauthTokensSchema do
  use Ecto.Schema

  alias Hilostory.Schema.EncryptedBinary

  @primary_key false

  schema "oauth_tokens" do
    field :access_token, EncryptedBinary, redact: true
    field :refresh_token, EncryptedBinary, redact: true
    field :refresh_token_expires_at, :utc_datetime_usec
  end
end
