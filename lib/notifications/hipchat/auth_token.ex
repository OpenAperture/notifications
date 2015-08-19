#
# == auth_token.ex
#
# This module contains the hipchat auth token logic
#
require Logger

defmodule OpenAperture.Notifications.Hipchat.AuthToken do

  alias OpenAperture.Notifications.Configuration

  @doc """
  Starts a `GenServer` process linked to the current process.

  This is often used to start the `GenServer` as part of a supervision tree.

  Once the server is started, it calls the `init/1` function in the given `module`
  passing the given `args` to initialize it. To ensure a synchronized start-up
  procedure, this function does not return until `init/1` has returned.

  Note that a `GenServer` started with `start_link/3` is linked to the
  parent process and will exit in case of crashes. The GenServer will also
  exit due to the `:normal` reasons in case it is configured to trap exits
  in the `init/1` callback.

  ## Return values

  If the server is successfully created and initialized, the function returns
  `{:ok, pid}`, where pid is the pid of the server. If there already exists a
  process with the specified server name, the function returns
  `{:error, {:already_started, pid}}` with the pid of that process.

  If the `init/1` callback fails with `reason`, the function returns
  `{:error, reason}`. Otherwise, if it returns `{:stop, reason}`
  or `:ignore`, the process is terminated and the function returns
  `{:error, reason}` or `:ignore`, respectively.
  """
  @spec start_link() :: {:ok, pid} | {:error, String.t}
  def start_link() do
    create()
  end

  @doc """
  This module contains the hipchat auth token logic

  ## Return values

  If the server is successfully created and initialized, the function returns
  `{:ok, pid}`, where pid is the pid of the server. If there already exists a
  process with the specified server name, the function returns
  `{:error, {:already_started, pid}}` with the pid of that process.

  If the `init/1` callback fails with `reason`, the function returns
  `{:error, reason}`. Otherwise, if it returns `{:stop, reason}`
  or `:ignore`, the process is terminated and the function returns
  `{:error, reason}` or `:ignore`, respectively.
  """
  @spec create() :: {:ok, pid} | {:error, String.t}
  def create() do
  	token_string = Configuration.get_hipchat_config("HIPCHAT_AUTH_TOKENS", :auth_tokens)
  	if token_string == nil || String.length(token_string) == 0 do
  		Logger.error("No hipchat auth tokens were provided!")
  		tokens = []
    else
      tokens = String.split(token_string, ",")
  	end

    Agent.start_link(fn -> tokens end, name: __MODULE__)
  end

  @doc """
  This module contains the logic for storing the OpenAperture workflow queue.

  ## Return values

  If the server is successfully created and initialized, the function returns
  `{:ok, pid}`, where pid is the pid of the server. If there already exists a
  process with the specified server name, the function returns
  `{:error, {:already_started, pid}}` with the pid of that process.

  If the `init/1` callback fails with `reason`, the function returns
  `{:error, reason}`. Otherwise, if it returns `{:stop, reason}`
  or `:ignore`, the process is terminated and the function returns
  `{:error, reason}` or `:ignore`, respectively.
  """
  @spec create() :: {:ok, pid} | {:error, String.t}
  def create!() do
    case create() do
      {:ok, pid} -> pid
      {:error, reason} -> raise "Failed to create AuthToken:  #{reason}"
    end
  end

  @doc """
  Updates the auth tokens

  ## Options

  The `new_hosts` option defines the workflow queue

  ## Return values

  :ok
  """
  @spec update(list) :: :ok
  def update(new_hosts) do
  	Agent.update(__MODULE__, fn _ -> new_hosts end)
  end

  @doc """
  Method to retrieve the list of currently known hosts in the auth tokens.

  ## Return Values

  The `new_hosts` option defines the workflow queue

  ## Return values

  :ok
  """
  def all() do
    Agent.get(__MODULE__, fn hosts -> hosts end)
  end

  @doc """
  Method to retrieve a hipchat authentication token

  ## Return Values

  String
  """
  @spec get_next_token() :: String.t
  def get_next_token() do
    tokens = Agent.get(__MODULE__, fn hosts -> hosts end)

    token_cnt = length tokens
    case token_cnt do
      0 ->
        Logger.error("Unable to find a valid Hipchat Auth Token!  No tokens were configured!")
        ""
      1 -> List.first(tokens)
      _ ->
        token_idx = :random.uniform(token_cnt)-1
        {token, _cur_idx} = Enum.reduce tokens, {"", 0}, fn (current_token, {token, cur_idx}) ->
          if cur_idx == token_idx do
            {current_token, cur_idx+1}
          else
            {token, cur_idx+1}
          end
        end

        token
    end
  end
end
