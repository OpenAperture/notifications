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
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "3d3a84eabf4ba0a3a827a61c4d99cdbf0ab49a0d", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "86cf2c324434f9899416881219e03c0f959c2896", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "4b9146507ab50789fec4696b96f79642add2b502", override: true},

      {:timex, "~> 0.13.3", override: true},
      {:timex_extensions, git: "https://github.com/OpenAperture/timex_extensions.git", ref: "1665c1df90397702daf492c6f940e644085016cd", override: true},

      {:mailman, "~> 0.1.0"},
      {:eiconv, github: "OpenAperture/eiconv"},

      # test dependencies
      {:exvcr,  github: "parroty/exvcr", only: [:test], override: true},
      {:meck,   "~> 0.8.3", override: true},
      {:ex_doc, "~> 0.7.3", only: :test, override: true},
      {:earmark, "~> 0.1.17", only: :test},
    ]
  end
end
