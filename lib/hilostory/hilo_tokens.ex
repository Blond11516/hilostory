defmodule Hilostory.HiloTokens do
  alias Hilostory.Infrastructure.OauthTokensRepository

  def has_valid_tokens() do
    OauthTokensRepository.get() != nil
  end
end
