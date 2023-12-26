defmodule TrueAnomaly.Instruments.JackalMk2 do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :instrument1, :string
    field :instrument3, :string
    field :instrument4, :string
  end

  def changeset(instruments, params) do
    instruments
    |> cast(params, ~w(instrument1 instrument3 instrument4)a)
    |> validate_required([:instrument1, :instrument3, :instrument4])
  end
end
