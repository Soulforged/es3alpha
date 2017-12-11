defmodule Es3Alpha.Storage.Store do
  @moduledoc false

  @spec write(key :: any, chunk :: binary) :: :ok | {:error, reason :: any}
  @spec read(key :: any) :: chunk :: binary | {:error, reason :: any}
  @spec delete(key :: any) :: :ok | {:error, reason :: any}

  def write(key, chunk) do
    case :mnesia.transaction(fn -> :mnesia.write {Chunk, key, chunk} end) do
      {:aborted, reason} -> {:error, reason}
      {:atomic, _} -> :ok
    end
  end

  def read(key) do
    result = :mnesia.transaction(fn -> :mnesia.read({Chunk, key}) end)
    case result do
      {:atomic, [{Chunk, _, chunk}]} -> chunk
      _ -> {:error, :not_found}
    end
  end

  def delete(key) do
    case :mnesia.transaction(fn -> :mnesia.delete({Chunk, key}) end) do
      {:aborted, reason} -> {:error, reason}
      {:atomic, _} -> :ok
    end
  end
end
