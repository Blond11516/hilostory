defmodule ZoiJsonCodegen do
  @moduledoc """
  Generate Elixir source code (as a string) for a Zoi schema from a JSON example.

  Example usage:
  ```elixir
  json = ~S/{"foo": "bar", "baz": 1}/
  ZoiJsonCodegen.write_module_from_json(json, "MyApp.ExternalApiResponse")
  ```

  Will write the file `lib/my_app/external_api_response.ex` with the contents:
  ```elixir
  defmodule MyApp.ExternalApiResponse do
    @moduledoc false

    def schema() do
      Zoi.object(%{
        "foo": Zoi.string(),
        "baz": Zoi.integer()
      })
    end
  """

  def write_module_from_json(json, module_name) do
    body = code_from_json(json)
    mod_file = Path.join("lib", Macro.underscore("#{module_name}") <> ".ex")

    source = """
    defmodule #{module_name} do
      @moduledoc false

      def #{:schema}() do
        #{body}
      end
    end
    """

    formatted = Code.format_string!(source) |> IO.iodata_to_binary()
    File.write!(mod_file, formatted)
    mod_file
  end

  def code_from_json(json) when is_binary(json) do
    json
    |> Jason.decode!()
    |> build_schema_ast()
    |> ast_to_string()
  end

  # Convert quoted AST to pretty Elixir source string
  defp ast_to_string(ast) do
    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  # Build AST for a Zoi schema call from decoded JSON
  defp build_schema_ast(v) when is_map(v) do
    map_ast =
      {:%{}, [],
       Enum.map(v, fn {k, vv} ->
         {k, build_schema_ast(vv)}
       end)}

    quote(do: Zoi.object(unquote(map_ast)))
  end

  defp build_schema_ast(v) when is_list(v) do
    inner =
      case v do
        [h | _] -> build_schema_ast(h)
        [] -> quote(do: Zoi.any())
      end

    quote(do: Zoi.array(unquote(inner)))
  end

  defp build_schema_ast(v) when is_binary(v), do: quote(do: Zoi.string())
  defp build_schema_ast(v) when is_integer(v), do: quote(do: Zoi.integer())
  defp build_schema_ast(v) when is_float(v), do: quote(do: Zoi.number())
  defp build_schema_ast(v) when is_boolean(v), do: quote(do: Zoi.boolean())
  defp build_schema_ast(_), do: quote(do: Zoi.optional(Zoi.any()))
end
