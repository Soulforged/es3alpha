defmodule Es3Alpha.EndpointTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias HTTPoison.Response
  alias Es3Alpha.Storage

  @host "http://localhost:8080"

  setup do
    Storage.clear()
    {:ok, []}
  end

  test "home displays a small help" do
    assert %Response{status_code: 200, body: body} = HTTPoison.get!(@host)
    assert body =~ ~s(<li><a href="files">List files</a></li>)
  end

  test "list empty storage" do
    assert %Response{status_code: 200, body: body} = HTTPoison.get!("#{@host}/files")
    assert "[]" = body
  end

  test "adding a file requires a body" do
    assert %Response{status_code: 400, body: resp_body}
      = HTTPoison.post!("#{@host}/files", "",
        [{"content-type", "application/json; charset=utf-8"}])
    assert ~s({"error":"missing params: 'name', 'content'"}) = resp_body
  end

  test "add a file, read it, then delete it" do
    body = Poison.encode! %{"name" => "file1", "content" => "some content ~!@ Ññ"}

    assert %Response{status_code: 200, body: created_res_url}
      = HTTPoison.post!("#{@host}/files", body,
        [{"content-type", "application/json; charset=utf-8"}])
    assert "http://localhost:8080/files/file1" = created_res_url

    assert %Response{status_code: 200, body: resp_body}
      = HTTPoison.get!(created_res_url,
        [{"content-type", "text/plain; charset=utf-8"}])
    assert "some content ~!@ Ññ" = resp_body

    assert %Response{status_code: 204} = HTTPoison.delete!("#{@host}/files/file1")
    assert %Response{status_code: 404} = HTTPoison.get!("#{@host}/files/file1")
  end
end
