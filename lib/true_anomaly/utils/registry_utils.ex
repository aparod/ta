defmodule TrueAnomaly.Utils.RegistryUtils do
  alias TrueAnomaly.Files.File

  @spec name_for(atom()) :: atom()
  def name_for(:registry),
    do: :ComponentRegistry

  def name_for(:file_parsers_supervisor),
    do: :FileParsersSupervisor

  def name_for(:file_system_watcher),
    do: :FileSystemWatcher

  @spec name_for(atom(), File.t()) :: atom()
  def name_for(:data_persister, %File{} = file),
    do: :"DataPersister:#{file.id}"

  def name_for(:data_staging_agent, %File{} = file),
    do: :"DataStagingAgent:#{file.id}"

  def name_for(:file_parser_supervisor, %File{} = file),
    do: :"FileParserSupervisor:#{file.id}"

  def name_for(:file_reader, %File{} = file),
    do: :"FileReader:#{file.id}"

  @spec via_registry(atom(), File.t()) :: {:via, Registry, {atom(), atom()}}
  def via_registry(:data_persister, %File{} = file),
    do: name_for(:data_persister, file) |> via()

  def via_registry(:data_staging_agent, %File{} = file),
    do: name_for(:data_staging_agent, file) |> via()

  def via_registry(:file_parser_supervisor, %File{} = file),
    do: name_for(:file_parser_supervisor, file) |> via()

  def via_registry(:file_reader, %File{} = file),
    do: name_for(:file_reader, file) |> via()

  defp via(component_name),
    do: {:via, Registry, {name_for(:registry), component_name}}
end
