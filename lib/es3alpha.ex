defmodule Es3Alpha do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: StorageSupervisor]]),
      worker(Es3Alpha.Storage, [])
    ]

    opts = [strategy: :one_for_one, name: Es3Alpha.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
