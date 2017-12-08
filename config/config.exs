use Mix.Config

config :es3alpha, nodes: [:n1@localhost,:n2@localhost]

import_config "#{Mix.env}.exs"
