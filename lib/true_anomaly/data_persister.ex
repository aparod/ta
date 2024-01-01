defmodule TrueAnomaly.DataPersister do
  use GenServer

  import TrueAnomaly.Utils.RegistryUtils

  require Logger

  alias TrueAnomaly.DataStagingAgent
  alias TrueAnomaly.FileParsersSupervisor
  alias TrueAnomaly.Repo
  alias TrueAnomaly.Telemetry.Telemetry

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = via_registry(:data_persister, file)

    GenServer.start_link(__MODULE__, file, name: name)
  end

  def init(%TrueAnomaly.Files.File{} = file) do
    state = %{file: file}

    {:ok, state}
  end

  def handle_cast(:start, state) do
    {:noreply, state, {:continue, :set_timer}}
  end

  def handle_continue(:set_timer, state) do
    Process.send_after(self(), :persist_records, 1_000)

    {:noreply, state}
  end

  def handle_info(:persist_records, state) do
    DataStagingAgent.get_chunk(state.file)
    |> persist_records(state)
  end

  defp persist_records(records, state) when length(records) > 0 do
    Enum.map(records, fn {line_num, _, record} ->
      changeset = Telemetry.changeset(record)

      if changeset.valid? do
        Repo.insert(changeset)

        {line_num, :persisted, record}
      else
        error =
          "[DataPersister] File #{state.file.id} failed " <>
            "validation on line #{line_num}: #{inspect(changeset.errors)}."

        Logger.warning(error)

        {line_num, :error, record}
      end
    end)
    |> then(fn lines ->
      # Update the Agent with the results
      DataStagingAgent.update_line_statuses(state.file, lines)
    end)

    {:noreply, state, {:continue, :set_timer}}
  end

  defp persist_records([], state) do
    Logger.info("[DataPersister] File #{state.file.id} processing complete.")

    # Update the file record with relevant statistics
    attrs =
      DataStagingAgent.get_stats(state.file)
      |> Map.put(:status, :complete)

    TrueAnomaly.Files.update(state.file, attrs)

    # Delete the file from the ingest folder
    File.rm!(state.file.name)

    # Terminate all processes for this file now that the import is complete
    FileParsersSupervisor.remove_file_parser(state.file)

    {:noreply, state}
  end

  ### Client functions ###

  @spec start(TrueAnomaly.Files.File.t()) :: :ok
  def start(%TrueAnomaly.Files.File{} = file) do
    name = via_registry(:data_persister, file)

    GenServer.cast(name, :start)
  end
end
