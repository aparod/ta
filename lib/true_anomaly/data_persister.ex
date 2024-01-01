defmodule TrueAnomaly.DataPersister do
  use GenServer

  import TrueAnomaly.Utils.RegistryUtils

  require Logger

  alias TrueAnomaly.Repo
  alias TrueAnomaly.Telemetry.Telemetry

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = via_registry(:data_persister, file)

    GenServer.start_link(__MODULE__, file, name: name)
  end

  def init(%TrueAnomaly.Files.File{} = file) do
    state = %{
      file: file,
      records: []
    }

    {:ok, state, {:continue, :set_timer}}
  end

  def handle_continue(:set_timer, state) do
    Process.send_after(self(), :persist_records, 3_000)

    {:noreply, state}
  end

  def handle_info(:persist_records, state) do
    # Persist up to 25 records at a time
    records = Enum.slice(state.records, 0..24)

    Enum.each(records, fn {line_num, record} ->
      changeset = Telemetry.changeset(record)

      if changeset.valid? do
        Repo.insert(changeset)
      else
        error =
          "[DataPersister] File #{state.file.id} failed " <>
            "validation on line #{line_num}: #{inspect(changeset.errors)}."

        Logger.warning(error)
      end
    end)

    new_state = %{state | records: Enum.drop(state.records, length(records))}

    {:noreply, new_state, {:continue, :set_timer}}
  end

  def handle_cast({:enqueue_records, records}, state) do
    new_records = state.records ++ records

    {:noreply, %{state | records: new_records}}
  end
end
