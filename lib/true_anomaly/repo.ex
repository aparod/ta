defmodule TrueAnomaly.Repo do
  use Ecto.Repo,
    otp_app: :true_anomaly,
    adapter: Ecto.Adapters.Postgres
end
