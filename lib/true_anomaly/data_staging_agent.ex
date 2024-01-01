defmodule TrueAnomaly.DataStagingAgent do
  use Agent

  import TrueAnomaly.Utils.RegistryUtils

  alias TrueAnomaly.Files.File

  @chunk_size 50

  def start_link(%File{} = file) do
    name = via_registry(:data_staging_agent, file)

    Agent.start_link(fn -> [] end, name: name)
  end

  @spec append_data(File.t(), list(tuple())) :: :ok
  def append_data(%File{} = file, data) when is_list(data) do
    name = via_registry(:data_staging_agent, file)

    Agent.cast(name, &(&1 ++ data))
  end

  @spec get_chunk(File.t()) :: any()
  def get_chunk(%File{} = file) do
    func = fn state ->
      state
      |> Enum.filter(&(elem(&1, 1) == :normalized))
      |> Enum.reduce_while([], fn {line_num, _, line}, acc ->
        # Builds up a list until reaching @chunk_size
        acc = [{line_num, :persisting, line} | acc]

        if length(acc) < @chunk_size, do: {:cont, acc}, else: {:halt, acc}
      end)
      |> then(fn chunk ->
        # Update the Agent's state to record the statuses of the lines that
        # are being handed off for processing
        new_state =
          Enum.reduce(chunk, state, fn {line_num, _, _} = row, acc ->
            List.update_at(acc, line_num - 1, fn _ -> row end)
          end)

        # Not essential, but reverse the chunk to preserve the original order
        {Enum.reverse(chunk), new_state}
      end)
    end

    Agent.get_and_update(via_registry(:data_staging_agent, file), func)
  end

  @spec sort_data(File.t()) :: :ok
  def sort_data(%File{} = file) do
    name = via_registry(:data_staging_agent, file)

    Agent.cast(name, fn state ->
      Enum.sort(state, &(elem(&1, 0) <= elem(&2, 0)))
    end)
  end

  @spec update_line_statuses(File.t(), list(tuple())) :: :ok
  def update_line_statuses(%File{} = file, lines) when is_list(lines) do
    name = via_registry(:data_staging_agent, file)

    Agent.cast(name, fn state ->
      Enum.reduce(lines, state, fn {line_num, _, _} = row, acc ->
        List.update_at(acc, line_num - 1, fn _ -> row end)
      end)
    end)
  end

  @spec get_stats(File.t()) :: map()
  def get_stats(%File{} = file) do
    name = via_registry(:data_staging_agent, file)

    Agent.get(name, fn state ->
      %{
        total_lines: length(state),
        imported_lines: Enum.count(state, & (elem(&1, 1) == :persisted)),
        errors: Enum.count(state, & (elem(&1, 1) == :error))
      }
    end)
  end

  @spec get_state(File.t()) :: any()
  def get_state(%File{} = file) do
    name = via_registry(:data_staging_agent, file)

    Agent.get(name, & &1)
  end
end
