# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

config :cloudos_messaging,
	username: "user",
	password: "pass",
	virtual_host: "staging",
	host: "rabbithost",
	exchange: "us-east-1b"

config :hipchat,
  auth_tokens: "123abc,234xyz",
  default_room_name: "Default Events Rooms"

config :logger, :console,
  level: :debug