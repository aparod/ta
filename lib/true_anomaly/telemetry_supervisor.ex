defmodule TrueAnomaly.TelemetrySupervisor do
  use Supervisor

  import TrueAnomaly.Utils.RegistryUtils

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: name_for(:registry)},
      TrueAnomaly.FileSystemWatcher,
      TrueAnomaly.FileParsersSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
