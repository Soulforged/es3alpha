# Es3alpha

## Requirements
* erlang 20 or greater
* elixir 1.5 or greater

## Setup
mix deps.get && mix test

## Usage
* Open a node on host1: iex --name primary@host1 -S mix
* Open another node on hostx: iex --name primary@hostx -S mix

NOTE: at least one of those nodes should be listed in the config/config.exs file
as: `config :es3alpha, nodes: [:"node1@127.0.0.1",:"node2@127.0.0.1"]`

* Navigate to http://localhost:8080 for further instructions
