defmodule TrueAnomaly.FileReader do
  use GenServer

  @chunk_size 50

  def start_link(%TrueAnomaly.Files.File{} = file) do
    name = :"FileReader#{file.id}"

    GenServer.start_link(__MODULE__, file, name: name)
  end

  def init(%TrueAnomaly.Files.File{} = file) do
    state = %{
      file: file,
      file_stream: nil,
      satellite_type: nil,
      lines: []
    }

    {:ok, state, {:continue, :get_satellite_type}}
  end

  def handle_continue(:get_satellite_type, state) do
    fs = File.stream!(state[:file].name)

    header = Stream.take(fs, 1) |> Enum.at(0) |> Jason.decode!()
    satellite_type = header["satellite_type"] |> String.to_atom()
    state = %{state | file_stream: fs, satellite_type: satellite_type}

    {:noreply, state, {:continue, :read_lines}}
  end

  def handle_continue(:read_lines, state) do
    lines =
      state.file_stream
      |> Stream.drop(1)
      |> Enum.with_index()
      |> Enum.map(fn {line, idx} -> {idx + 1, nil, line} end)

    state = %{state | lines: lines}

    {:noreply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_chunk, _from, state) do
    start_index =
      Enum.find_index(state.lines, fn {_, status, _} -> status == nil end)

    if start_index == nil do
      {:reply, {state.satellite_type, []}, state}
    else
      end_index = start_index + @chunk_size - 1

      # Grab the lines for processing
      chunk =
        state.lines
        |> Enum.slice(start_index..end_index)

      # Update the status of the lines in the state
      head =
        if start_index > 0 do
          Enum.slice(state.lines, 0..(start_index - 1))
        else
          []
        end

      middle =
        Enum.map(chunk, fn {line_num, _, line} -> {line_num, :processsing, line} end)

      tail = Enum.slice(state.lines, (end_index + 1)..-1//1)

      {:reply, {state.satellite_type, chunk}, %{state | lines: head ++ middle ++ tail}}
    end
  end

  ### Client functions ###

  def get_state(%TrueAnomaly.Files.File{} = file) do
    name = :"FileReader#{file.id}"

    GenServer.call(name, :get_state)
  end

  def get_chunk(%TrueAnomaly.Files.File{} = file) do
    name = :"FileReader#{file.id}"

    GenServer.call(name, :get_chunk)
  end
end
