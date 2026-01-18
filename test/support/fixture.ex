defmodule Hilostory.Fixture do
  @moduledoc false
  @base_fixtures_path URI.parse("test/fixtures")

  def string(path) do
    local_path = String.replace_prefix(path, "/", "")

    @base_fixtures_path
    |> URI.append_path("/" <> local_path)
    |> URI.to_string()
    |> File.read!()
  end

  def json(path), do: path |> string() |> JSON.decode!()
end
