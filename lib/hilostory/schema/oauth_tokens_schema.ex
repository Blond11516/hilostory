defmodule Hilostory.Schema.OauthTokensSchema do
  use Ecto.Schema

  alias Hilostory.Schema.EncryptedBinary

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t(),
          refresh_token_expires_at: DateTime.t()
        }

  @primary_key false

  schema "oauth_tokens" do
    field :access_token, EncryptedBinary, redact: true
    field :refresh_token, EncryptedBinary, redact: true
    field :refresh_token_expires_at, :utc_datetime_usec
  end
end
