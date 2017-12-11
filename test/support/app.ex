defmodule Es3Alpha.Support.App do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    this_node = [:"primary@127.0.0.1"]
    nodes = Application.get_env(:es3alpha, :nodes, []) ++ this_node
    :net_kernel.start(this_node)
    :mnesia.start()
    :mnesia.create_schema(nodes)
    :mnesia.create_table(File, [attributes: [:name, :chunks], ram_copies: nodes])
    :mnesia.create_table(Chunk, [attributes: [:key, :chunk], ram_copies: nodes])
    :mnesia.wait_for_tables([File, Chunk], 5000)

    children = [
      worker(Es3Alpha.Storage, [[name: Es3Alpha.Storage]]),
      worker(Es3Alpha.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: Es3Alpha.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
