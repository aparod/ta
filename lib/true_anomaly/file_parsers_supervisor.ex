defmodule TrueAnomaly.FileParsersSupervisor do
  use DynamicSupervisor

  alias TrueAnomaly.FileParserSupervisor
  alias TrueAnomaly.Files.File

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_file_parser(%File{} = file) do
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, {FileParserSupervisor, file})
  end
end
