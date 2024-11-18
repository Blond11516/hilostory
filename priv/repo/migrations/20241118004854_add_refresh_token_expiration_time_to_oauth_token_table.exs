defmodule Hilostory.Repo.Migrations.AddRefreshTokenExpirationTimeToOauthTokenTable do
  use Ecto.Migration

  def change do
    alter table("oauth_tokens") do
      add :refresh_token_expires_at, :timestamptz, null: false
    end
  end
end
