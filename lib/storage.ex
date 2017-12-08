defmodule Es3Alpha.Storage do
  @moduledoc false
  use GenServer

  alias Es3Alpha.Storage.Store
  alias __MODULE__.NodeAgent

  @spec write(name :: iodata, object :: binary) :: :ok | {:error, reason :: any}
  @spec read(name :: iodata) :: object :: binary | {:error, reason :: any}
  @spec delete(name :: iodata) :: :ok | {:error, reason :: any}

  @nodes        Application.get_env(:es3alpha, :nodes, [])
  @chunk_size   Application.get_env(:es3alpha, :chunk_size, 256)
  @key_pattern  ~r/.+_(\d+)$/

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  def init(:ok) do
    :mnesia.create_schema([node()])
    :rpc.multicall([node()], :application, :start, [:mnesia])
    :mnesia.create_table(File, [attributes: [:name, :chunks],
      index: [], disc_copies: [node()]])
    :mnesia.create_table(Chunk, [attributes: [:key, :chunk],
      index: [], disc_copies: [node()]])
    :mnesia.wait_for_tables([File, Chunk], 5000)
    {:ok, :ok}
  end

  def write(name, object) do
    {:ok, node_agent} = NodeAgent.start_link
    written_chunks = split(object)
    |> Enum.with_index
    |> Task.async_stream(&write_chunk(&1, name, node_agent))
    |> Enum.reduce([], fn {:ok, chunk_key}, acc -> acc ++ [chunk_key] end)
    :mnesia.transaction(fn -> :mnesia.write {File, name, written_chunks} end)
    :ok
  end

  def read(name) do
    file = :mnesia.transaction(fn -> :mnesia.read{File, name} end)
    case file do
      {:atomic, [{File, _, chunks}]} ->
        chunks
        |> Task.async_stream(&read_chunk/1)
        |> Enum.reduce([], fn {:ok, chunk}, acc -> acc ++ [chunk] end)
        |> Enum.sort(fn c1, c2 -> c1.org_index > c2.org_index end)
        |> Enum.reduce("", fn %{chunk: chunk}, acc -> acc <> chunk end)
      _ -> {:error, :not_found}
    end
  end

  def delete(name) do

  end

  defp read_chunk({node, key}) do
    [_, org_index] = Regex.run(@key_pattern, key)
    chunk = :rpc.call(node, Store, :read, [key])
    IO.inspect({chunk, org_index})
    %{org_index: org_index, chunk: chunk}
  end

  defp write_chunk({chunk, index}, name, node_agent) do
    node = NodeAgent.get(node_agent)
    key = "#{name}_#{index}"
    {:atomic, _} = :rpc.call(node, Store, :write, [key, chunk])
    {node, key}
  end

  defp split(object), do: split(object, [])
  defp split(object, acc) when bit_size(object) <= @chunk_size, do: [object|acc]

  defp split(object, acc) do
    <<chunk::size(@chunk_size), rest::bitstring>> = object
    split(rest, [<<chunk::size(@chunk_size)>> | acc])
  end

  defmodule NodeAgent do
    use Agent

    @nodes Application.get_env(:es3alpha, :nodes, [])

    def start_link, do: Agent.start_link(fn -> @nodes end, name: __MODULE__)

    def get(agent) do
      Agent.get_and_update(agent, fn nodes -> next_node(nodes) end)
    end

    defp next_node([]), do: next_node(@nodes)
    defp next_node([next|rest]), do: {next, rest}
  end
end
