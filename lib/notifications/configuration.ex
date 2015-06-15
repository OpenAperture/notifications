#
# == configuration.ex
#
# This module contains the logic to retrieve configuration from either the environment or configuration files
#
defmodule OpenAperture.Notifications.Configuration do
  @doc """
  Method to retrieve the currently assigned exchange id

  ## Options

  ## Return values

  The exchange identifier
  """
  @spec get_current_exchange_id() :: String.t()
  def get_current_exchange_id do
    System.get_env()
    get_config("EXCHANGE_ID", :openaperture_notifications, :exchange_id)
  end

  @doc """
  Method to retrieve the currently assigned exchange id

  ## Options

  ## Return values

  The exchange identifier
  """
  @spec get_current_broker_id() :: String.t()
  def get_current_broker_id do
    System.get_env()
    get_config("BROKER_ID", :openaperture_notifications, :broker_id)
  end

  @doc """
  Method to retrieve the currently assigned queue name (for "notifications_hipchat")

  ## Options

  ## Return values

  The exchange identifier
  """
  @spec queue_name(String) :: String.t
  def queue_name(key) do
    get_config(
      "#{String.upcase(key)}_QUEUE_NAME",
      :openaperture_notifications,
      String.to_atom(key)
    )
  end

  @doc """
  Method to retrieve a configuration option from the environment or config settings, for the hipchat application

  ## Options

  The `env_name` option defines the environment variable name

  The `config_name` option defines the config variable name (atom)

  ## Return values

  Value
  """
  @spec get_hipchat_config(String.t(), term) :: String.t()
  def get_hipchat_config(env_name, config_name) do
    get_config(env_name, :hipchat, config_name)
  end

  @doc """
  Returns a `%Mailman.SomeConfig{}` structure containg SMTP relay's settings.
  """
  @spec smtp :: %Mailman.SmtpConfig{}
  def smtp do
    if Mix.env == :test do
      %Mailman.TestConfig{}
    else
      %Mailman.SmtpConfig{
        relay: '#{get_config("SMTP_URI", :openaperture_notifications, :smtp_uri)}',
        port:  '#{get_config("SMTP_PORT", :openaperture_notifications, :smtp_port)}',
        username: '#{get_config("SMTP_USERNAME", :openaperture_notifications, :smtp_username)}',
        password: '#{get_config("SMTP_PASSWORD", :openaperture_notifications, :smtp_password)}',
        tls: :always,
        auth: :always,
        ssl: false
      }
    end
  end

  @doc false
  # Method to retrieve a configuration option from the environment or config settings
  #
  ## Options
  #
  # The `env_name` option defines the environment variable name
  #
  # The `application_config` option defines the config application name (atom)
  #
  # The `config_name` option defines the config variable name (atom)
  #
  ## Return values
  #
  # Value
  #
  @spec get_config(String.t(), term, term) :: String.t()
  defp get_config(env_name, application_config, config_name) do
    System.get_env(env_name) || Application.get_env(application_config, config_name)
  end
end
