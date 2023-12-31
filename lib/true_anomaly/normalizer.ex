defmodule TrueAnomaly.Normalizer do
  @moduledoc """
  The entrypoint for all data normalization.  Based on the satellite type,
  normalization is delegated to a specific module.
  """

  @spec normalize(map(), atom()) :: {:ok, map()} | {:error, any()}
  def normalize(%{} = data, satellite_type) when is_atom(satellite_type) do
    module_for(satellite_type).normalize(data)
  end

  defp module_for(satellite_type) do
    case satellite_type do
      :jackal_mk1 -> TrueAnomaly.Normalizer.JackalMk1
      :jackal_mk2 -> TrueAnomaly.Normalizer.JackalMk2
    end
  end
end
