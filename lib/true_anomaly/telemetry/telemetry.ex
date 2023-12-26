defmodule TrueAnomaly.Telemetry.Telemetry do
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias __MODULE__

  schema "telemetry" do
    belongs_to :file, TrueAnomaly.Files.File

    field :velocity, :float
    field :altitude, :float
    field :latitude, :float
    field :longitude, :float
    field :timestamp, :utc_datetime_usec

    polymorphic_embeds_one(:instruments,
      types: [
        jackal_mk1: TrueAnomaly.Instruments.JackalMk1,
        jackal_mk2: TrueAnomaly.Instruments.JackalMk2
      ],
      on_type_not_found: :raise,
      on_replace: :update
    )
  end

  def changeset(%{} = attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(%Telemetry{} = telemetry, %{} = attrs) do
    telemetry
    |> cast(attrs, [:velocity, :altitude, :latitude, :longitude, :timestamp, :file_id])
    |> cast_polymorphic_embed(:instruments, required: true)
    |> validate_required([:velocity, :altitude, :latitude, :longitude, :timestamp])
  end
end
