defmodule TrueAnomaly.FileParserSupervisor do
  @moduledoc """
  A supervisor for monitoring the  components needed for processing a given
  telemetry package.
  """

  use Supervisor

  import TrueAnomaly.Utils.RegistryUtils

  alias TrueAnomaly.Files.File

  def start_link(%File{} = file) do
    name = via_registry(:file_parser_supervisor, file)

    Supervisor.start_link(__MODULE__, file, name: name)
  end

  @impl true
  def init(%File{} = file) do
    children = [
      {TrueAnomaly.DataStagingAgent, file},
      {TrueAnomaly.FileReader, file},
      {TrueAnomaly.DataPersister, file}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
