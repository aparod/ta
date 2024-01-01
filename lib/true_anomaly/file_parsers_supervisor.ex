defmodule TrueAnomaly.FileParsersSupervisor do
  use DynamicSupervisor

  import TrueAnomaly.Utils.RegistryUtils

  alias TrueAnomaly.FileParserSupervisor
  alias TrueAnomaly.Files.File

  def start_link(init_arg) do
    name = name_for(:file_parsers_supervisor)

    DynamicSupervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_file_parser(%File{} = file) do
    name = name_for(:file_parsers_supervisor)

    DynamicSupervisor.start_child(name, {FileParserSupervisor, file})
  end

  def remove_file_parser(%File{} = file) do
    registry_name = name_for(:registry)
    file_parser_supervisor = name_for(:file_parser_supervisor, file)

    case Registry.lookup(registry_name, file_parser_supervisor) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(name_for(:file_parsers_supervisor), pid)

      _ ->
        :ok
    end
  end
end
