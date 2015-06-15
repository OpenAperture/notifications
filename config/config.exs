use Mix.Config

config :mailer, 
	from: System.get_env("SMTP_FROM")

config :openaperture_notifications,
  hipchat: "notifications_hipchat",
  email:   "notifications_email"

import_config "#{Mix.env}.exs"
