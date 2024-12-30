defmodule Hilostory.Infrastructure.Hilo.Models do
  @spec parse(%{String.t() => any()}, module(), %{atom() => (any() -> any())}) :: struct()
  def parse(data, model_module, field_parsers \\ %{})

  def parse(datum, model_module, field_parsers)
      when is_list(datum) and is_atom(model_module) and is_map(field_parsers) do
    Enum.map(datum, &parse(&1, model_module, field_parsers))
  end

  def parse(data, model_module, field_parsers)
      when is_map(data) and is_atom(model_module) and is_map(field_parsers) do
    data
    |> Map.new(fn {key, value} ->
      field_key =
        key
        |> Recase.to_snake()
        |> String.to_existing_atom()

      parsed_value =
        case field_parsers do
          %{^field_key => parser} -> parser.(value)
          _ -> value
        end

      {field_key, parsed_value}
    end)
    |> then(&struct!(model_module, &1))
  end
end
