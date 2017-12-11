use Mix.Config

config :es3alpha, nodes: [:"node1@127.0.0.1",:"node2@127.0.0.1"]

import_config "#{Mix.env}.exs"
