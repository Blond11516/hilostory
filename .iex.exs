case Application.ensure_loaded(:hilostory) do
  {:error, {~c"no such file or directory", ~c"hilostory.app"}} ->
    nil

  :ok ->
    {:ok, modules} = :application.get_key(:hilostory, :modules)

    for module <- modules,
        module
        |> Atom.to_string()
        |> String.starts_with?("Elixir.Hilostory.Infrastructure.Hilo.Models.") do
      module
    end
    |> Code.ensure_all_loaded!()

    import_file("./iex_helpers.exs")
end

import_if_available(IexHelpers)

if Code.ensure_loaded?(IexAccessTokenStore) do
  IexAccessTokenStore.start_link()
end

IEx.configure(auto_reload: true)
