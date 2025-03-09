defmodule Hilostory.HiloTokens do
  @moduledoc false
  alias Hilostory.Infrastructure.OauthTokensRepository

  def has_valid_tokens do
    OauthTokensRepository.get() != nil
  end
end
