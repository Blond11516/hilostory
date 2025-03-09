defmodule Hilostory.Schema.EncryptedBinary do
  @moduledoc false
  use Cloak.Ecto.Binary, vault: Hilostory.Vault
end
