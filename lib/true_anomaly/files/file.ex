defmodule TrueAnomaly.Files.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  schema "files" do
    field :name, :string
    field :status, Ecto.Enum, values: [:processing, :complete]
    field :result, :string

    timestamps()
  end

  def changeset(%File{} = file, %{} = attrs) do
    file
    |> cast(attrs, [:name, :status, :result])
  end
end
