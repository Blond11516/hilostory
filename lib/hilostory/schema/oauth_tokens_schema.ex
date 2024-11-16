defmodule Hilostory.Schema.OauthTokensSchema do
  use Ecto.Schema

  alias Hilostory.Schema.EncryptedBinary

  @primary_key false

  schema "oauth_tokens" do
    field :access_token, EncryptedBinary, redact: true
    field :refresh_token, EncryptedBinary, redact: true
  end
end
