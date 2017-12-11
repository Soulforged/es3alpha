defmodule Es3Alpha.RestHandlers.Util do
  @moduledoc false

  def url(req) do
    host = :cowboy_req.host(req)
    scheme = :cowboy_req.scheme(req)
    port = :cowboy_req.port(req)
    path = :cowboy_req.path(req)
    "#{scheme}://#{host}:#{port}#{path}"
  end
end
