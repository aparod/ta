defmodule TrueAnomaly.DataNormalizer do
  use GenServer

  require Logger

  alias TrueAnomaly.Telemetry.Telemetry

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = :"DataNormalizer#{file.id}"

    GenServer.start_link(__MODULE__, file, name: name)
  end

  def init(%TrueAnomaly.Files.File{} = file) do
    state = %{
      file: file
    }

    {:ok, state, {:continue, :set_timer}}
  end

  def handle_continue(:set_timer, state) do
    Process.send_after(self(), :process_chunk, 1_000)

    {:noreply, state}
  end

  def handle_info(:process_chunk, state) do
    {satellite_type, lines} = GenServer.call(:"FileReader#{state.file.id}", :get_chunk)

    changesets =
      Enum.reduce(lines, [], fn {line_num, _, line}, acc ->
        json =
          line
          |> Jason.decode!(keys: :atoms)
          |> normalize_data(satellite_type)
          |> Map.put(:file_id, state.file.id)

        changeset = Telemetry.changeset(json)

        if changeset.valid? do
          [changeset | acc]
        else
          error =
            "[DataNormalization] File #{state.file.id} failed " <>
              "validation on line #{line_num}: #{inspect(changeset.errors)}."

          Logger.warning(error)

          acc
        end
      end)

    GenServer.cast(:"DataPersister#{state.file.id}", {:enqueue_records, changesets})

    {:noreply, state, {:continue, :set_timer}}
  end

  defp normalize_data(json, :jackal_mk1) do
    fields = [:velocity, :altitude, :latitude, :longitude]

    attrs = Map.take(json, fields)

    {:ok, timestamp, _} = DateTime.from_iso8601(json.timestamp)
    attrs = Map.put(attrs, :timestamp, timestamp)

    instruments = %{
      __type__: :jackal_mk1,
      instrument1: json.instrument1,
      instrument2: json.instrument2
    }

    Map.put(attrs, :instruments, instruments)
  end

  defp normalize_data(json, :jackal_mk2) do
    {:ok, timestamp, _} = DateTime.from_iso8601(json.ts)

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

    Map.put(attrs, :instruments, instruments)
  end
end
