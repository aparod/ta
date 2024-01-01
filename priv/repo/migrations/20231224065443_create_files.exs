defmodule TrueAnomaly.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :name, :string, null: false
      add :status, :string, null: false
      add :total_lines, :integer
      add :imported_lines, :integer
      add :errors, :integer

      timestamps()
    end

    create index(:files, :name)
  end
end
