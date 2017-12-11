defmodule Es3Alpha.RestHandlers.Home do
  @moduledoc false

  def init(req, opts), do: {:cowboy_rest, req, opts}

  def content_types_provided(req, state), do:
    {[{"text/html", :home_to_html}, {"text/plain", :home_to_text}], req, state}

  def home_to_html(req, state) do
    body = """
        <html>
          <head>
          	<meta charset="utf-8">
          	<title>REST Es3 API</title>
          </head>
          <body>
            <ul>
              <li><a href="files">List files</a></li>
            </ul>
            <p>To add a file: POST /files, in the body: {"name": `filename`, "content": `content of the file`}</p>
            <p>To read a file: GET /files/:filename</p>
            <p>To delete a file: DELETE /files/:filename</p>
          </body>
        </html>
    """
  	{body, req, state}
  end

  def home_to_text(req, state), do: {"Hola", req, state}
end
