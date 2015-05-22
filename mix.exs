defmodule OpenAperture.Notifications.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :openaperture_notifications,
     version: get_version,
     elixir: "~> 1.0",      
     elixirc_paths: ["lib"],
     escript: [main_module: OpenAperture.Notifications],
     deps: deps]
  end

  # Generate a project version with the first 10 characters of the commit hash.
  # This is done so that new releases can be built even if the @version
  # attribute hasn't been bumped.
  defp get_version do
    #commit_hash  = :os.cmd('git rev-parse HEAD') |> List.to_string |> String.slice(0..9)
    #"#{@version}-#{commit_hash}"
    @version
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
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

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ex_doc, github: "elixir-lang/ex_doc", only: [:test]},
      {:markdown, github: "devinus/markdown", only: [:test]},        
      {:poison, "~> 1.3.1"},
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "8c51d099ec79473b23b3c385c072e6bf2219fba7", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "5d442cfbdd45e71c1101334e185d02baec3ef945", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "4d65d2295f2730bc74ec695c32fa0d2478158182", override: true},

      {:timex, "~> 0.12.9"},
      {:timex_extensions, git: "https://github.com/OpenAperture/timex_extensions.git", ref: "ab9d8820625171afbb80ccba1aa48feeb43dd790", override: true},

      #test dependencies
      {:exvcr, github: "parroty/exvcr", override: true},
      {:meck, "0.8.2", override: true}     
    ]
  end
end
