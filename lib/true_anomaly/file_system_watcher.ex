defmodule TrueAnomaly.FileSystemWatcher do
  use GenServer

  require Logger

  alias TrueAnomaly.Files

  @files_dir Path.relative("files/ingest")

  def start_link(_default) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, MapSet.new(), {:continue, :set_timer}}
  end

  def handle_continue(:set_timer, state) do
    Process.send_after(self(), :scan_filesystem, 5_000)

    {:noreply, state}
  end

  def handle_info(:scan_filesystem, state) do
    filenames =
      File.ls!(@files_dir)
      |> Enum.reject(&(&1 == ".gitkeep"))
      |> Enum.map(fn file -> Enum.join([Path.expand("."), @files_dir, file], "/") end)

    state =
      Enum.reduce(filenames, state, fn filename, acc ->
        if MapSet.member?(state, filename) do
          # We've already seen and started processing the file. Ignore it.
          acc
        else
          # A new file is ready for processing.
          case Files.create(%{name: filename}) do
            {:ok, file} ->
              TrueAnomaly.FileParsersSupervisor.add_file_parser(file)
              MapSet.put(state, filename)

            {:error, reason} ->
              Logger.error("[FilesystemWatcher] #{inspect(reason)}")
              acc
          end
        end
      end)

    {:noreply, state, {:continue, :set_timer}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  ### Client functions ###

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end
end
