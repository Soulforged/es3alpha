defmodule Es3Alpha.Storage do
  @moduledoc false
  use GenServer

  alias Es3Alpha.Storage.Store

  @spec write(name :: iodata, object :: binary) :: :ok | {:error, reason :: any}
  @spec read(name :: iodata) :: object :: binary | {:error, reason :: any}
  @spec delete(name :: iodata) :: :ok | {:error, reason :: any}

  @nodes      Application.get_env(:es3alpha, :nodes, [])
  @chunk_size Application.get_env(:es3alpha, :chunk_size, 256)

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  def init(:ok) do
    :mnesia.create_schema(@nodes)
    :rpc.multicall(@nodes, :application, :start, [:mnesia])
    :mnesia.create_table(File, [attributes: [:name, :chunks],
      index: [], disc_copies: @nodes])
    :mnesia.create_table(Chunk, [attributes: [:key, :chunk],
      index: [], disc_copies: @nodes])
    :mnesia.wait_for_tables([File, Chunk], 5000)
    {:ok, :ok}
  end

  @doc """
  Dispatch the given `mod`, `fun`, `args` request
  to the appropriate node based on the `bucket`.
  """
  def write(name, object) do
    written_chunks = split(object)
    |> Enum.with_index
    |> Task.async_stream(&write_chunk(&1, name))
    |> Enum.reduce([], fn {:ok, chunk_key}, acc -> acc ++ [chunk_key] end)
    :mnesia.transaction(fn -> :mnesia.write{File, name, written_chunks} end)
    :ok
  end

  def read(name) do
    file = :mnesia.transaction(fn -> :mnesia.read{File, name} end)
    case file do
      {:atomic, [{File, _, chunks}]} ->
        chunks
        |> Enum.with_index
        |> Task.async_stream(&read_chunk/1)
        |> Enum.reduce([], fn {:ok, indexed_chunk}, acc -> acc ++ [indexed_chunk] end)
        |> Enum.sort(fn {i1, c1}, {i2, c2} -> i1 < i2 end)
        |> Enum.reduce("", fn {chunk, _}, acc -> acc <> chunk end)
      _ -> {:error, :not_found}
    end
  end

  def delete(name) do

  end

  defp read_chunk({{node, key}, index}) do
    chunk = :rpc.call(node, Store, :read, [key])
    {chunk, index}
  end

  defp write_chunk({chunk, index}, name) do
    [node|_] = @nodes
    key = "#{name}_#{index}"
    Node.spawn_link(node, Store, :write, [key, chunk])
    {node, key}
  end

  defp split(object), do: split(object, [])
  defp split(object, acc) when bit_size(object) <= @chunk_size, do: [object | acc]

  defp split(object, acc) do
    <<chunk::size(@chunk_size), rest::bitstring>> = object
    split(rest, [<<chunk::size(@chunk_size)>> | acc])
  end
end
