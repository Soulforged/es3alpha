defmodule Es3Alpha.Endpoint do
  @moduledoc false
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :ok, opts)

  def init(:ok) do
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/", Es3Alpha.RestHandlers.Home, []},
        {"/files/:name", Es3Alpha.RestHandlers.File, []},
        {"/files", Es3Alpha.RestHandlers.Files, []}

    ]}])
    res = :cowboy.start_clear(:http, [port: 8080], %{env: %{dispatch: dispatch}})
    case res do
      {:error, :eaddrinuse} ->
        IO.puts("address already in use, could not start listener")
        :ignore
      {:error, reason} -> {:stop, reason}
      res -> res
    end
  end
end
