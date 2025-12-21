defmodule Hilostory.Graphql.SubscriptionQuery do
  @moduledoc false
  @enforce_keys [:variables, :operation_name, :query]
  defstruct [:variables, :operation_name, :query]

  @type t :: %__MODULE__{
          variables: %{String.t() => String.t()},
          operation_name: String.t(),
          query: String.t()
        }

  def from_query(query, variables) when is_binary(query) and is_map(variables) do
    [operation_name | _] =
      query
      |> String.replace_prefix("subscription ", "")
      |> String.split("(", parts: 2)

    %__MODULE__{
      variables: variables,
      operation_name: operation_name,
      query: query
    }
  end
end
