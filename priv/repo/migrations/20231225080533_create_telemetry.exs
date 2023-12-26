defmodule TrueAnomaly.Repo.Migrations.CreateTelemetry do
  use Ecto.Migration

  def change do
    create table(:telemetry) do
      add :velocity, :float, null: false
      add :altitude, :float, null: false
      add :latitude, :float, null: false
      add :longitude, :float, null: false
      add :instruments, :map
      add :timestamp, :utc_datetime_usec, null: false

      add :file_id, references(:files)
    end

    create index(:telemetry, :timestamp)
  end
end
