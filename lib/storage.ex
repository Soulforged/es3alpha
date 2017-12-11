defmodule Es3Alpha.Storage do
  @moduledoc false
  use GenServer

  alias Es3Alpha.Storage.Store
  alias __MODULE__.NodeAgent

  @spec write(name :: iodata, object :: binary) :: :ok | {:error, reason :: any}
  @spec read(name :: iodata) :: object :: binary | {:error, reason :: any}
  @spec delete(name :: iodata) :: :ok | {:error, reason :: any}

  @chunk_size      Application.get_env(:es3alpha, :chunk_size, 256)
  @key_pattern     ~r/.+_(\d+)$/

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  @doc "will check for available nodes first and then start the node agent"
  def init(:ok) do
    nodes = Application.get_env(:es3alpha, :nodes, [])
    {:ok, node_agent} = NodeAgent.start_link(fn -> {nodes, nodes} end)
    {:ok, node_agent}
  end

  def write(name, object), do: GenServer.call(__MODULE__, {:write, name, object})

  def read(name), do: GenServer.call(__MODULE__, {:read, name})

  def delete(name), do: GenServer.call(__MODULE__, {:delete, name})

  def list() do
    {:atomic, result} = :mnesia.transaction(fn -> :mnesia.match_object({File, :_, :_}) end)
    result |> Enum.reduce([], fn {File, key, _}, acc -> acc ++ [key] end)
  end

  def clear(), do: list() |> Enum.map(&delete/1)

  def handle_call({:read, name}, _, node_agent) do
    file = :mnesia.transaction(fn -> :mnesia.read {File, name} end)
    reply = case file do
      {:atomic, [{File, _, chunks}]} ->
        reduced_chunks = chunks
        |> Task.async_stream(&read_chunk/1)
        |> Enum.reduce([], fn {:ok, chunk}, acc -> acc ++ [chunk] end)
        case Enum.member?(reduced_chunks, {:error, :missing_chunk}) do
          true -> {:error, :missing_chunks}
          _ ->
            reduced_chunks
            |> Enum.sort(fn c1, c2 -> c1.org_index > c2.org_index end)
            |> Enum.reduce("", fn %{chunk: chunk}, acc -> acc <> chunk end)
        end
      _ -> {:error, :not_found}
    end
    {:reply, reply, node_agent}
  end

  def handle_call({:write, name, object}, _, node_agent) do
    written_chunks = split(object)
    |> Enum.with_index
    |> Task.async_stream(&write_chunk(&1, name, node_agent))
    |> Enum.reduce([], fn {:ok, chunk_key}, acc -> acc ++ [chunk_key] end)
    res = case :mnesia.transaction(fn -> :mnesia.write {File, name, written_chunks} end) do
      {:aborted, reason} -> {:error, reason}
      _ -> :ok
    end
    {:reply, res, node_agent}
  end

  def handle_call({:delete, name}, _, node_agent) do
    file = :mnesia.transaction(fn -> :mnesia.read {File, name} end)
    case file do
      {:atomic, [{File, _, chunks}]} ->
        chunks
        |> Task.async_stream(&rm_chunk/1)
      _ -> :ok
    end
    res = case  :mnesia.transaction(fn -> :mnesia.delete {File, name} end) do
      {:aborted, reason} -> {:error, reason}
      _ -> :ok
    end
    {:reply, res, node_agent}
  end

  defp rm_chunk({node, key}), do: :rpc.call(node, Store, :delete, [key])

  defp read_chunk({node, key}) do
    [_, org_index] = Regex.run(@key_pattern, key)
    case :rpc.call(node, Store, :read, [key]) do
      {:badrpc, _} -> {:error, :missing_chunk}
      chunk -> %{org_index: String.to_integer(org_index), chunk: chunk}
    end
  end

  defp write_chunk({chunk, index}, name, node_agent) do
    node = NodeAgent.get(node_agent)
    case node do
      {:error, _} -> node
      _ ->
        key = "#{name}_#{index}"
        :rpc.call(node, Store, :write, [key, chunk])
        {node, key}
    end
  end

  defp split(object), do: split(object, [])
  defp split(object, acc) when bit_size(object) <= @chunk_size, do: [object|acc]

  defp split(object, acc) do
    <<chunk::size(@chunk_size), rest::bitstring>> = object
    split(rest, [<<chunk::size(@chunk_size)>> | acc])
  end

  defmodule NodeAgent do
    use Agent

    def start_link(fun), do: Agent.start_link(fun, name: __MODULE__)

    def get(agent) do
      Agent.get_and_update(agent, fn available -> next_node(available) end)
    end

    defp next_node({[], all}), do: next_node({all, all})
    defp next_node({[next|rest], all}) do
      case Node.ping(next) do
        :pang -> next_node({rest, all})
        :pong -> {next, {rest, all}}
      end
    end
  end
end
