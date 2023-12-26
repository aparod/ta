defmodule TrueAnomaly.Instruments.JackalMk1 do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :instrument1, :string
    field :instrument2, :string
  end

  def changeset(instruments, params) do
    instruments
    |> cast(params, ~w(instrument1 instrument2)a)
    |> validate_required([:instrument1, :instrument2])
  end
end
