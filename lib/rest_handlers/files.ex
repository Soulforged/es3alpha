defmodule Es3Alpha.RestHandlers.Files do
  @moduledoc false
  import Es3Alpha.RestHandlers.Util

  alias Es3Alpha.Storage

  def init(req, opts), do: {:cowboy_rest, req, opts}

  def allowed_methods(req, state), do: {["GET", "OPTIONS", "HEAD", "POST", "DELETE"], req, state}

  def content_types_accepted(req, state) do
    {[{{"application", "json", [{"charset", "utf-8"}]}, :files_from_json}],
      req, state}
  end

  def content_types_provided(req, state) do
    {[{"text/plain", :files_to_text}, {"application/json", :files_to_json}], req, state}
  end

  def files_from_json(%{method: "POST", has_body: true} = req, state) do
    {:ok, req_body, req} = :cowboy_req.read_body(req)
    %{"name" => name, "content" => content} = req_body |> Poison.decode!
    {status, body} = case Storage.write(name, content) do
      {:error, reason} -> {400, Poison.encode!(%{"error" => reason})}
      _ -> {200, "#{url(req)}/#{name}"}
    end
    req = :cowboy_req.reply(status,
      %{"content-type" => "text/plain; charset=utf-8"}, body, req)
  	{body, req, state}
  end

  def delete_resource(%{bindings: %{name: name}} = req, state) do
    Storage.delete(name)
    {true, req, state}
  end

  def files_from_json(%{method: "POST"} = req, state) do
    body = Poison.encode!(%{"error" => "missing params: 'name', 'content'"})
    req = :cowboy_req.reply(400,
      %{"content-type" => "application/json; charset=utf-8"}, body, req)
    {body, req, state}
  end

  def files_to_json(%{bindings: %{name: name}} = req, state) do
    {status, body} = case Storage.read(name) do
      {:error, :not_found} -> {404, Poison.encode!(%{"error" => "not found"})}
      {:error, reason} -> {400, Poison.encode!(%{"error" => reason})}
      content -> {200, Poison.encode!(%{"name" => name, "content" => content})}
    end
    req = :cowboy_req.reply(status,
      %{"content-type" => "application/json; charset=utf-8"}, body, req)
  	{body, req, state}
  end

  def files_to_json(req, state) do
    files = Storage.list()
    body = Poison.encode!(files)
  	{body, req, state}
  end

  def files_to_text(%{bindings: %{name: name}} = req, state) do
    {status, body} = case Storage.read(name) do
      {:error, :not_found} -> {404, "not found"}
      {:error, reason} -> {400, reason}
      content -> {200, content}
    end
    req = :cowboy_req.reply(status,
      %{"content-type" => "text/plain; charset=utf-8"}, body, req)
  	{body, req, state}
  end

  def files_to_text(req, state), do: files_to_json(req, state)
end
