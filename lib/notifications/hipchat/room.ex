#
# == room.ex
#
# This module contains the logic for resolving hipchat room information
#
require Logger

defmodule OpenAperture.Notifications.Hipchat.Room do

  alias OpenAperture.Notifications.Hipchat.AuthToken

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
  @spec start_link() :: {:ok, pid} | {:error, String.t()}
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Method to resolve room IDS, based on room names.

  ## Option Values

  The `room_names` option defines the room name list to be resolved

  ## Return Values

  A list of room IDs

  """
  @spec resolve_room_ids(List) :: List
  def resolve_room_ids(room_names) do
    if (room_names == nil || length(room_names) == 0) do
      []
    else
      options = Agent.get(__MODULE__, fn options -> options end)
      if (options[:room_names] == nil) do
        options = Map.put(options, :room_names, %{})
      end

      {room_ids, resolved_options} = Enum.reduce room_names, {[], options}, fn(room_name, {room_ids, resolved_options})->
        if resolved_options[:room_names][room_name] != nil do
          room_ids = room_ids ++ [resolved_options[:room_names][room_name]]
        else
          room_id = get_room_id(room_name)
          if (room_id != nil) do
            room_ids = room_ids ++ [room_id]

            update_room_names = Map.put(resolved_options[:room_names], room_name, room_id)
            resolved_options = Map.put(resolved_options, :room_names, update_room_names)
          end
        end

        {room_ids, resolved_options}
      end
      Agent.update(__MODULE__, fn _ -> resolved_options end)
      room_ids
    end
  end

  @doc false
  # Retrieves a HipChat room ID
  #
  ## Options
  #   Required:
  #   * name — String
  #
  # ## Return values
  #   Integer or nil
  @spec get_room_id(String) :: term
  def get_room_id(name) do
    Logger.debug("Retrieving hipchat room ID for '#{name}'")
    case :httpc.request(:get, {'https://api.hipchat.com/v2/room/#{URI.encode(name)}?auth_token=#{AuthToken.get_next_token}', []}, [], []) do
      {:ok, {{_,return_code, _}, _, body}} ->
        case return_code do
          200 -> 
            JSON.decode!(body)["id"]
          _   -> 
            error_body = JSON.decode!(body)
            Logger.error("Failed to send hipchat notification to room '#{name}'!  The server responded with #{error_body["status"]} - #{error_body["message"]}")
            nil
        end
      {:error, {failure_reason, _}} ->
        Logger.error("Failed to send hipchat notification to room '#{name}'!  The server responded with #{inspect failure_reason}")
        nil
    end
  end
end
