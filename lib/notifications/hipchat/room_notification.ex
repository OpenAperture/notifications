#
# == hipchat_room_notification.ex
#
# This module contains the hipchat room notification (https://www.hipchat.com/docs/apiv2/method/send_room_notification) options.
#
require Logger
require Timex.Date
require Timex.Time

defmodule OpenAperture.Notifications.Hipchat.RoomNotification do
  use Timex

  @doc """
  Creates a `GenServer` representing hipchat room notification (https://www.hipchat.com/docs/apiv2/method/send_room_notification).

  ## Option Values

  The following options may be passed into the `options` value:
  * color (optional):  yellow, green, red, purple, gray, random
  * message (required):  message body
  * notify (optional):  boolean
  * message_format (required):  html, text

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
  @spec create(Map) :: {:ok, pid} | {:error, String.t()}
  def create(options) do
    resolved_options = Map.merge(options, %{notification_type: :room_notification})
    if (resolved_options[:color] == nil) do
      resolved_options = Map.merge(resolved_options, %{color: "gray"})
    end

    if (resolved_options[:message_prefix] == nil) do
      message_prefix = "#{get_timestamp()}"
    else
      message_prefix = "#{get_timestamp()} #{resolved_options[:message_prefix]}"
      resolved_options = Map.delete(resolved_options, :message_prefix)
    end

    if (resolved_options[:message] == nil) do
      resolved_options = Map.merge(resolved_options, %{message: "#{message_prefix}:  "})
    else
      message = resolved_options[:message]
      resolved_options = Map.delete(resolved_options, :message)
      resolved_options = Map.merge(resolved_options, %{message: "#{message_prefix}:  #{message}"})
    end

    if (resolved_options[:notify] == nil) do
      resolved_options = Map.merge(resolved_options, %{notify: false})
    end

    if (resolved_options[:message_format] == nil) do
      resolved_options = Map.merge(resolved_options, %{message_format: "html"})
    end

    Agent.start_link(fn -> resolved_options end)
  end

  @doc """
  Creates a `GenServer` representing hipchat room notification (https://www.hipchat.com/docs/apiv2/method/send_room_notification),
  and returns PID.  Throws an error if create fails.

  ## Option Values

  The following options may be passed into the `options` value:
  * color (optional):  yellow, green, red, purple, gray, random
  * message (required):  message body
  * notify (optional):  boolean
  * message_format (required):  html, text
  """
  @spec create!(Map) :: pid
  def create!(options) do
    case OpenAperture.Notifications.Hipchat.RoomNotification.create(options) do
      {:ok, notification} -> notification
      {:error, reason} -> raise "Failed to create hipchat room notification: #{reason}"
    end
  end

  @doc false
  # Method to generate a string timestamp
  #
  ## Return Values
  #
  # String
  #
  @spec get_timestamp() :: String.t()
  defp get_timestamp() do
    date = Date.now()
    DateFormat.format!(date, "{RFC1123}")
  end

  @doc """
  Method to retrieve the list of currently known options in the room notification.

  ## Return Values

  The `new_hosts` option defines an array of the options that are available for the room notification.

  ## Return values

  :ok
  """
  def options(notification) do
    Agent.get(notification, fn options -> options end)
  end
end
