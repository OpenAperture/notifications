use Mix.Config

config :mailer, from: "openaperture@lexmark.com"

config :openaperture_notifications,
  hipchat: "notifications_hipchat",
  email: "notifications_email"

import_config "#{Mix.env}.exs"
