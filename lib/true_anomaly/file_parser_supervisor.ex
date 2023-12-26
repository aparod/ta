defmodule TrueAnomaly.FileParserSupervisor do
  use Supervisor

  alias TrueAnomaly.Files.File

  def start_link(%File{} = file) do
    name = :"FileParserSupervisor#{file.id}"

    Supervisor.start_link(__MODULE__, file, name: name)
  end

  @impl true
  def init(%File{} = file) do
    children = [
      {TrueAnomaly.FileReader, file},
      {TrueAnomaly.DataNormalizer, file},
      {TrueAnomaly.DataPersister, file}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
