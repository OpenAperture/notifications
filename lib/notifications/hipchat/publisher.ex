#
# == publisher.ex
#
# This module contains the server for managing/handling HipChat notifications
#

require Logger
require Timex.Date
require Timex.Time

defmodule OpenAperture.Notifications.Hipchat.Publisher do
  
  @moduledoc """
  This module contains the server for managing/handling HipChat notifications
  """

  use GenServer
  use Timex

  alias OpenAperture.Notifications.Hipchat.RoomNotification
  alias OpenAperture.Notifications.Hipchat.AuthToken

  @doc """
  Starts a `GenServer` process linked to the current process.

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
    GenServer.start_link(__MODULE__, %{})
  end

  def create!() do
    case GenServer.start_link(__MODULE__, %{}) do
      {:ok, pid} -> pid
      {:error, reason} -> raise "Failed to start Hipchat Publisher:  #{inspect reason}"
    end
  end

  @doc """
  Method to generate a new server and execute redeployment requests

  ## Options

  The `publisher` option is the PID of the GenServer

  The `options` option provides the details of the notification; currently the only supported notification is type :room_notification

  ## Returns

  :ok | {:error, reason}
  """
  @spec send_notification(pid, Map) :: :ok | {:error, String.t()}
  def send_notification(publisher, options) do
    if options[:room_notification] do
      GenServer.cast(publisher, {:room_notification, options})
    else
      Logger.error "Unknown hipchat notification type: #{inspect options[:notification_type]}"
    end
  end

  @doc """
  Sends an asynchronous request to the `server`, which will
  send out a Room Notification (https://www.hipchat.com/docs/apiv2/method/send_room_notification)

  This function returns `:ok` immediately, regardless of
  whether the destination node or server does exists, unless
  the server is specified as an atom.

  `handle_cast/2` will be called on the server to handle
  the request. In case the server is a node which is not
  yet connected to the caller one, the call is going to
  block until a connection happens. This is different than
  the behaviour in OTP's `:gen_server` where the message
  would be sent by another process, which could cause
  messages to arrive out of order.
  """
	def handle_cast({:room_notification, options}, state) do
		room_notification         = options[:room_notification]
		room_notification_options = RoomNotification.options(room_notification)

    Logger.debug("Sending a hipchat room notification to room #{room_notification_options[:room_id]}...")
    resolved_url = 'https://api.hipchat.com/v2/room/#{room_notification_options[:room_id]}/notification?auth_token=#{AuthToken.get_next_token}'

    body = '#{Poison.encode!(room_notification_options)}'
    case :httpc.request(:post, {resolved_url, [], 'application/json', body}, [], []) do
      {:ok, {{_,return_code, _}, headers, body}} ->
        case return_code do
          204 -> 
            {rate_limit, rate_limit_remaining, rate_limit_reset} = Enum.reduce headers, {nil, nil, nil}, fn (header, {rate_limit, rate_limit_remaining, rate_limit_reset}) ->
              cond do 
                elem(header, 0) == 'x-ratelimit-limit' || elem(header, 0) == 'X-Ratelimit-Limit' -> 
                  {val, _} = Integer.parse("#{elem(header, 1)}")
                  {val, rate_limit_remaining, rate_limit_reset}
                elem(header, 0) == 'x-ratelimit-remaining' || elem(header, 0) == 'X-Ratelimit-Remaining' -> 
                  {val, _} = Integer.parse("#{elem(header, 1)}")
                  {rate_limit, val, rate_limit_reset}
                elem(header, 0) == 'x-ratelimit-reset' || elem(header, 0) == 'X-Ratelimit-Reset' -> 
                  {val, _} = Integer.parse("#{elem(header, 1)}")
                  {rate_limit, rate_limit_remaining, val}
                true -> {rate_limit, rate_limit_remaining, rate_limit_reset}
              end
            end

            rate_reset_time = OpenAperture.Timex.Extensions.time_from_unix_timestamp(rate_limit_reset)
            rate_reset_timestamp = OpenAperture.Timex.Extensions.get_elapsed_timestamp(rate_reset_time)
            Logger.debug("Successfully send hipchat notification.  Rate limit is currently at #{rate_limit_remaining}/#{rate_limit}; next reset in #{rate_reset_timestamp}")

            if (rate_limit_remaining <= 0) do
              Logger.error("Error!  Unable to send additinoal hipchats - rate limit has been reached!")
            end
          _   -> 
            error_body = Poison.decode!("#{body}")
            Logger.error("Failed to send hipchat notification!  The server responded with #{error_body["error"]["code"]} - #{error_body["error"]["message"]}")
        end
      {:error, {failure_reason, _}} ->
        Logger.error ("Failed to send hipchat notification!  The server responded with #{inspect failure_reason}")
    end

    {:noreply, state}
	end
end