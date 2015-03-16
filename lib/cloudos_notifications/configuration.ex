#
# == configuration.ex
#
# This module contains the logic to retrieve configuration from either the environment or configuration files
#
defmodule CloudOS.Notifications.Configuration do

  @doc """
  Method to retrieve a configuration option from the environment or config settings, for the messaging application
   
  ## Options
   
  The `env_name` option defines the environment variable name
  
  The `config_name` option defines the config variable name (atom)
   
  ## Return values
   
  Value
  """ 
  @spec get_messaging_config(String.t(), term) :: String.t()
  def get_messaging_config(env_name, config_name) do
    get_config(env_name, :cloudos_messaging, config_name)
  end

  @doc """
  Method to retrieve a configuration option from the environment or config settings, for the hipchat application
   
  ## Options
   
  The `env_name` option defines the environment variable name
  
  The `config_name` option defines the config variable name (atom)
   
  ## Return values
   
  Value
  """ 
  @spec get_messaging_config(String.t(), term) :: String.t()
  def get_hipchat_config(env_name, config_name) do
    get_config(env_name, :hipchat, config_name)
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