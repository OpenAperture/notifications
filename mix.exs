defmodule OpenAperture.Notifications.Mixfile do
  use Mix.Project

  def project do
    [app: :openaperture_notifications,
     version: "0.0.2",
     elixir: "~> 1.0",
     elixirc_paths: ["lib"],
     escript: [main_module: OpenAperture.Notifications],
     deps: deps]
  end

  def application do
    [
      mod: { OpenAperture.Notifications, [] },
      applications: [
        :logger,
        :openaperture_messaging,
        :openaperture_manager_api,
        :openaperture_overseer_api
      ]
    ]
  end

  defp deps do
    [
      {:poison, "~> 1.4.0", override: true},
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "fa8eb8128176d010d29780251e4ce500068e3ec1", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "ab5334f276b308706a91e85ca27ba937bb02fb9f", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "25c779ea50565cdb3f783cba644294e6238ed72a", override: true},

      {:timex, "~> 0.12.9"},
      {:timex_extensions, git: "https://github.com/OpenAperture/timex_extensions.git", ref: "ab9d8820625171afbb80ccba1aa48feeb43dd790", override: true},

      {:mailman, "~> 0.1.0"},
      {:eiconv, github: "OpenAperture/eiconv"},

      # test dependencies
      {:exvcr,  github: "parroty/exvcr", only: [:test], override: true},
      {:meck,   "~> 0.8.3", only: [:test], override: true},
      {:ex_doc, "~> 0.7.3", only: :test, override: true},
      {:earmark, "~> 0.1.17", only: :test},
    ]
  end
end
