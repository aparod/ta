defmodule TrueAnomaly.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :name, :string, null: false
      add :status, :string, null: false

      timestamps()
    end

    create index(:files, :name)
  end
end
