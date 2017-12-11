defmodule Es3Alpha.RestHandlers.File do
  @moduledoc false

  alias Es3Alpha.Storage

  def init(req, opts), do: {:cowboy_rest, req, opts}

  def content_types_accepted(req, state) do
    {[{{"text", "plain", [{"charset", "utf-8"}]}, :file_from_text},
      {{"application", "json", [{"charset", "utf-8"}]}, :file_from_json}],
      req, state}
  end

  def content_types_provided(req, state) do
    {[{{"text", "plain", []}, :file_to_text},
      {{"application", "json", []}, :file_to_json}], req, state}
  end

  def allowed_methods(req, state), do:
    {["GET", "OPTIONS", "HEAD", "DELETE"], req, state}

  def delete_resource(%{bindings: %{name: name}} = req, state) do
    Storage.delete(name)
    {true, req, state}
  end

  def file_to_json(%{bindings: %{name: name}} = req, state) do
    {status, body} = case Storage.read(name) do
      {:error, :not_found} -> {404, Poison.encode!(%{"error" => "not found"})}
      {:error, reason} -> {400, Poison.encode!(%{"error" => reason})}
      content -> {200, Poison.encode!(%{"name" => name, "content" => content})}
    end
    req = :cowboy_req.reply(status,
      %{"content-type" => "application/json; charset=utf-8"}, body, req)
  	{body, req, state}
  end

  def file_to_text(%{bindings: %{name: name}} = req, state) do
    {status, body} = case Storage.read(name) do
      {:error, :not_found} -> {404, "not found"}
      {:error, reason} -> {400, reason}
      content -> {200, content}
    end
    req = :cowboy_req.reply(status,
      %{"content-type" => "text/plain; charset=utf-8"}, body, req)
  	{body, req, state}
  end
end
