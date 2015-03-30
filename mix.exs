defmodule CloudOS.Notifications.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :cloudos_notifications,
     version: get_version,
     elixir: "~> 1.0",      
     elixirc_paths: ["lib"],
     escript: [main_module: CloudOS.Notifications],
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
      mod: { CloudOS.Notifications, [] },
      applications: [:logger, :cloudos_messaging]
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
      {:json, "~> 0.3.2"},
      {:cloudos_messaging, git: "https://#{System.get_env("GITHUB_OAUTH_TOKEN")}:x-oauth-basic@github.com/UmbrellaCorporation-SecretProjectLab/cloudos_messaging.git", ref: "2db6e25c6e596889f34ee9254c0198c98a180611", override: true},
      {:timex_extensions, git: "https://#{System.get_env("GITHUB_OAUTH_TOKEN")}:x-oauth-basic@github.com/UmbrellaCorporation-SecretProjectLab/timex_extensions.git", ref: "7cf7cea363155eb753415a2f2c4f7a81db520c53", override: true},

      #test dependencies
      {:exvcr, github: "parroty/exvcr", override: true, only: :test},
      {:meck, "0.8.2", only: :test}      
    ]
  end
end
