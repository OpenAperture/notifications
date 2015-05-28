use Mix.Config

config :mailer,
  from: "openaperture@lexmark.com"

import_config "#{Mix.env}.exs"
