defmodule Es3Alpha do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    nodes = [node()]
    :mnesia.create_schema(nodes)
    :mnesia.start()
    :mnesia.create_table(File, [attributes: [:name, :chunks],
      disc_copies: nodes])
    :mnesia.create_table(Chunk, [attributes: [:key, :chunk],
      disc_copies: nodes])
    :mnesia.wait_for_tables([File, Chunk], 5000)

    children = [
      worker(Es3Alpha.Storage, [[name: Es3Alpha.Storage]]),
      worker(Es3Alpha.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: Es3Alpha.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
