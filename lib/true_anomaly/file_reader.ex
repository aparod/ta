defmodule TrueAnomaly.FileReader do
  use GenServer

  import TrueAnomaly.Utils.RegistryUtils

  require Logger

  alias TrueAnomaly.DataPersister
  alias TrueAnomaly.DataStagingAgent
  alias TrueAnomaly.Normalizer

  @chunk_size 50

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = via_registry(:file_reader, file)

    GenServer.start_link(__MODULE__, file, name: name)
  end

  def init(%TrueAnomaly.Files.File{} = file) do
    state = %{
      file: file,
      file_stream: nil,
      satellite_type: nil
    }

    {:ok, state, {:continue, :process_header}}
  end

  def handle_continue(:process_header, state) do
    fs = File.stream!(state.file.name)

    header = Stream.take(fs, 1) |> Enum.at(0) |> Jason.decode!()
    satellite_type = header["satellite_type"] |> String.to_atom()
    state = %{state | file_stream: fs, satellite_type: satellite_type}

    {:noreply, state, {:continue, :read_lines}}
  end

  def handle_continue(:read_lines, state) do
    state.file_stream
    |> Stream.drop(1)
    |> Stream.with_index(1)
    |> Stream.chunk_every(@chunk_size)
    |> Enum.map(&normalize_and_stage_data(&1, state))
    |> Task.await_many()

    # Sort the rows in the agent now that all the data has been staged
    DataStagingAgent.sort_data(state.file)

    # Inform the data persister to begin processing records
    DataPersister.start(state.file)

    {:noreply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp normalize_and_stage_data(chunk, state) do
    # Each chunk is processed asynchronously
    Task.async(fn ->
      Enum.map(chunk, fn {line, idx} ->
        with {:ok, json} <- Jason.decode(line, keys: :atoms),
             {:ok, map} <- Normalizer.normalize(json, state.satellite_type) do
          {idx, :normalized, map}
        else
          {:error, reason} ->
            Logger.warning(
              "[FileReader] Error in file #{state.file.id} on line #{idx}: #{inspect(reason)}."
            )

            {idx, :error, inspect(reason)}
        end
      end)
      |> then(fn lines -> DataStagingAgent.append_data(state.file, lines) end)
    end)
  end

  ### Client functions ###

  def get_state(%TrueAnomaly.Files.File{} = file) do
    name = name_for(:file_reader, file)

    GenServer.call(name, :get_state)
  end
end
