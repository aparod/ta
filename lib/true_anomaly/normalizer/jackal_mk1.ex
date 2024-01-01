defmodule TrueAnomaly.Normalizer.JackalMk1 do
  @behaviour TrueAnomaly.Normalizer.Behaviour

  @spec normalize(map()) :: {:ok, map()} | {:error, any()}
  def normalize(json) when is_map(json) do
    with {:ok, timestamp, _} <- DateTime.from_iso8601(json.timestamp) do
      fields = [:velocity, :altitude, :latitude, :longitude]

      attrs = Map.take(json, fields)
      attrs = Map.put(attrs, :timestamp, timestamp)

      instruments = %{
        __type__: :jackal_mk1,
        instrument1: json.instrument1,
        instrument2: json.instrument2
      }

      {:ok, Map.put(attrs, :instruments, instruments)}
    end
  end
end
