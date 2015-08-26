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
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "380ce611a038dd8f7afb4fa7f660aeac06475af0", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "dc06f0a484410e7707dab8e96807d54a564557ed", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "67e1ec93cf1e12e5b0e86165f33ede703a886092", override: true},

      {:timex, "~> 0.13.3", override: true},
      {:timex_extensions, git: "https://github.com/OpenAperture/timex_extensions.git", ref: "bf6fe4b5a6bd7615fc39877f64b31e285b7cc3de", override: true},

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
