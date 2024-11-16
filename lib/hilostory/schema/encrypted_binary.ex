defmodule Hilostory.Schema.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: Hilostory.Vault
end
