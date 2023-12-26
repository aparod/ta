defmodule TrueAnomaly.DataPersister do
  use GenServer

  alias TrueAnomaly.Repo

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = :"DataPersister#{file.id}"

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

    Enum.each(records, fn record ->
      Repo.insert(record)
    end)

    new_state = %{state | records: Enum.drop(state.records, 25)}

    {:noreply, new_state, {:continue, :set_timer}}
  end

  def handle_cast({:enqueue_records, records}, state) do
    new_records = state.records ++ records

    {:noreply, %{state | records: new_records}}
  end
end
