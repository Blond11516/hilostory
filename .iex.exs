case Application.ensure_loaded(:hilostory) do
  {:error, {~c"no such file or directory", ~c"hilostory.app"}} ->
    nil

  :ok ->
    {:ok, modules} = :application.get_key(:hilostory, :modules)

    model_modules =
      for module <- modules,
          module
          |> Atom.to_string()
          |> String.starts_with?("Elixir.Hilostory.Infrastructure.Hilo.Models.") do
        module
      end

    Code.ensure_all_loaded!(model_modules)
    import_file("./iex/iex_helpers.exs")
    import_file("./iex/zoi_json_codegen.exs")
end

import_if_available(IexHelpers)

started? =
  Application.started_applications()
  |> Enum.map(&elem(&1, 0))
  |> Enum.any?(&(&1 == :hilostory))

if started? && Code.ensure_loaded?(IexAccessTokenStore) do
  IexAccessTokenStore.start_link()
end

IEx.configure(auto_reload: true)
