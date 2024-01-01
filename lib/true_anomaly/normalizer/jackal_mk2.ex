defmodule TrueAnomaly.Normalizer.JackalMk2 do
  @behaviour TrueAnomaly.Normalizer.Behaviour

  @spec normalize(map()) :: {:ok, map()} | {:error, any()}
  def normalize(json) when is_map(json) do
    with {:ok, timestamp, _} <- DateTime.from_iso8601(json.ts) do
      attrs = %{
        velocity: json.vel,
        altitude: json.alt,
        latitude: json.lat,
        longitude: json.long,
        timestamp: timestamp
      }

      instruments = %{
        __type__: :jackal_mk2,
        instrument1: json.instrument1,
        instrument3: json.instrument3,
        instrument4: json.instrument4
      }

      {:ok, Map.put(attrs, :instruments, instruments)}
    end
  end
end
