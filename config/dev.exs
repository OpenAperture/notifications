use Mix.Config

config :autostart,
  register_queues: true

config :openaperture_notifications,
  exchange_id: "4",
  broker_id:   "3"

config :openaperture_manager_api,
  manager_url:         System.get_env("MANAGER_URL"),
  oauth_login_url:     System.get_env("OAUTH_LOGIN_URL"),
  oauth_client_id:     System.get_env("OAUTH_CLIENT_ID"),
  oauth_client_secret: System.get_env("OAUTH_CLIENT_SECRET")

config :openaperture_overseer_api,
  module_type: :test,
  autostart:   false,
  exchange_id: "4",
  broker_id:   "3"

config :hipchat,
  auth_tokens:       System.get_env("HC_TOKEN"),
  default_room_name: System.get_env("HC_DEFAULT_ROOM")
