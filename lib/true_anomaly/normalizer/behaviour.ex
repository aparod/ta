defmodule TrueAnomaly.Normalizer.Behaviour do
  @callback normalize(map()) :: {:ok, map()} | {:error, any()}
end
