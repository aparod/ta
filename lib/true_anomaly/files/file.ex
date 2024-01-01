defmodule TrueAnomaly.Files.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  @type t :: %__MODULE__{
    id: integer,
    name:  String.t(),
    status: String.t(),
    total_lines: integer(),
    imported_lines: integer(),
    errors: integer(),

    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "files" do
    field :name, :string
    field :status, Ecto.Enum, values: [:processing, :complete]
    field :total_lines, :integer
    field :imported_lines, :integer
    field :errors, :integer

    timestamps()
  end

  def changeset(%File{} = file, %{} = attrs) do
    file
    |> cast(attrs, [:name, :status, :total_lines, :imported_lines, :errors])
  end
end
