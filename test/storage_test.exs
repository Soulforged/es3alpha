defmodule Es3Alpha.StorageTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Es3Alpha.Storage
  alias Es3Alpha.Storage.Store

  @chunk_size   Application.get_env(:es3alpha, :chunk_size, 256)

  setup do
    Storage.clear()
    {:ok, []}
  end

  test "file can be written and the read, and then deleted" do
    Storage.write("afile", "content")
    assert "content" = Storage.read("afile")
    Storage.delete("afile")
    assert {:error, :not_found} = Storage.read("afile")
  end

  test "empty storage returns empty list" do
    Storage.write("afile", "content")
    Storage.write("afile1", "content1")
    Storage.clear()

    assert [] = Storage.list()
  end

  test "can handle binary files" do
    data = File.read!("test/file.bin")
    Storage.write("binfile", data)
    assert data = Storage.read("binfile")
  end

  test "large enough files are spread between nodes" do
    data = File.read!("test/file.bin")
    Storage.write("binfile", data)

    [node1, node2] = Application.get_env(:es3alpha, :nodes, [])
    assert is_binary(:rpc.call(node1, Store, :read, ["binfile_1"]))
    assert is_binary(:rpc.call(node2, Store, :read, ["binfile_2"]))
  end

  test "non-available nodes are ignored" do
    org_env = Application.get_env(:es3alpha, :nodes, [])
    [first_node|_] = org_env
    Application.put_env(:es3alpha, :nodes, [first_node])

    data = File.read!("test/file.bin")
    Storage.write("binfile", data)

    assert data = Storage.read("binfile")

    Application.put_env(:es3alpha, :nodes, org_env)
  end
end
