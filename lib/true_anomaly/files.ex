defmodule TrueAnomaly.Files do
  alias TrueAnomaly.Files.File
  alias TrueAnomaly.Repo

  def all() do
    Repo.all(File)
  end

  def create(attrs \\ %{}) do
    %File{status: :processing, result: nil}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  def get_by_name(filename) do
    Repo.get_by(File, name: filename)
  end
end
