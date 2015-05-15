defmodule OpenAperture.Notifications.Dispatcher do
  require Logger
  use GenServer
  use OpenAperture.Messaging

  alias OpenAperture.Messaging
  alias Messaging.AMQP.ConnectionOptions, as: AMQPConnectionOptions
  alias Messaging.AMQP.QueueBuilder
  alias Messaging.AMQP.SubscriptionHandler

  alias OpenAperture.Notifications
  alias Notifications.Hipchat.RoomNotification
  alias Notifications.Hipchat.Room
  alias Notifications.Hipchat.Publisher, as: HipchatPublisher
  alias Notifications.Configuration
  alias Notifications.MessageManager

  alias OpenAperture.ManagerApi

  @moduledoc """
  Provides dispatching notification messsages to the appropriate GenServer(s).
  """

  @connection_options nil

  @doc """
  Starts GenServer. Returns `{:ok, pid}` or {:error, reason}``
  """
  @spec start_link() :: {:ok, pid} | {:error, String.t()}
  def start_link do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:error, reason} ->
        Logger.error("Failed to start OpenAperture Notifications:  #{inspect reason}")
        {:error, reason}
      {:ok, pid} ->
        try do
          if Application.get_env(:autostart, :register_queues, false) do
            case register_queues do
              {:ok, _} -> {:ok, pid}
              {:error, reason} ->
                Logger.error("Failed to register notification queues:  #{inspect reason}")
                {:ok, pid}
            end
          else
            {:ok, pid}
          end
        rescue e in _ ->
          Logger.error("An error occurred registering notification queues:  #{inspect e}")
          {:ok, pid}
        end
    end
  end

  @doc """
  Registers the notification queues with the Messaging system.
  Returns `:ok` or `{:error, reason}`
  """
  @spec register_queues() :: :ok | {:error, String.t()}
  def register_queues do
    Logger.debug("Registering notification queues...")

    notifications_hipchat_queue = QueueBuilder.build(ManagerApi.get_api, "notifications_hipchat", Configuration.get_current_exchange_id)

    options = OpenAperture.Messaging.ConnectionOptionsResolver.get_for_broker(ManagerApi.get_api, Configuration.get_current_broker_id)
    subscribe(options, notifications_hipchat_queue, fn(payload, _meta, %{subscription_handler: subscription_handler, delivery_tag: delivery_tag} = async_info) ->
      try do
        Logger.debug("Starting to process request #{delivery_tag}")
        MessageManager.track(async_info)
        trigger_notifications(payload, async_info)
      catch
        :exit, code   ->
          Logger.error("Message #{delivery_tag} Exited with code #{inspect code}.  Payload:  #{inspect payload}")
          SubscriptionHandler.acknowledge(subscription_handler, delivery_tag)
        :throw, value ->
          Logger.error("Message #{delivery_tag} Throw called with #{inspect value}.  Payload:  #{inspect payload}")
          SubscriptionHandler.acknowledge(subscription_handler, delivery_tag)
        what, value   ->
          Logger.error("Message #{delivery_tag} Caught #{inspect what} with #{inspect value}.  Payload:  #{inspect payload}")
          SubscriptionHandler.acknowledge(subscription_handler, delivery_tag)
      end
    end)
  end

  @doc """
  Triggers notifications of all types. Returns `:ok` or `{:error, reason}`.
  """
  @spec trigger_notifications(Map, Map) :: :ok | {:error, String.t}
  def trigger_notifications(payload, async_info) do
    case send_all_notifications(payload) do
      :ok              -> acknowledge_request(async_info)
      {:error, reason} -> reject_request(async_info, reason)
    end
  end

  defp send_all_notifications(payload) do
    try do
      send_hipchat_notifications(payload)
      send_emails(payload)
    rescue e ->
      Logger.error("Sending notifications failed: #{inspect e}")
      {:error, inspect(e)}
    end
  end

  @doc false
  @spec acknowledge_request(Map) :: :ok
  defp acknowledge_request(async_info) do
    %{handler: subscription_handler, tag: delivery_tag} = async_info
    SubscriptionHandler.acknowledge(subscription_handler, delivery_tag)
    MessageManager.remove(delivery_tag)
    :ok
  end

  @doc false
  @spec reject_request(Map, String.t()) :: {:error, String.t}
  defp reject_request(async_info, reason) do
    %{subcription_andler: subscription_handler, delivery_tag: delivery_tag} = async_info
    SubscriptionHandler.reject(subscription_handler, delivery_tag, false)
    {:error, reason}
  end

  def send_emails(payload) do
  end

  @doc """
  Deliver payload to the HipChat publisher. Returns `:ok` or `{:error, reason}`.
  """
  @spec send_hipchat_notifications(Map) :: :ok | {:error, String.t()}
  def send_hipchat_notifications(payload) do
    # Until there's a strong usecase for requiring requeue of failed HC messages,
    # simply ack/reject here rather than tracking the delivery tags separately.
    color        = if (payload[:is_success]), do: "green", else: "red"
    default_room = Configuration.get_hipchat_config("HIPCHAT_DEFAULT_ROOM_NAME", :default_room_name)

    room_names = if payload[:notifications][:hc_rooms] do
      payload[:notifications][:hc_rooms]
      |> Enum.reduce Map.put(%{}, default_room, default_room), fn (room, room_map) ->
          Map.put(room_map, room, room)
         end
      |> Map.keys
    else
      [default_room]
    end

    room_ids = Room.resolve_room_ids(room_names)
    Enum.reduce room_ids, :ok, fn (room_id, result) ->
      if result == :ok do
        notification_params = %{
          room_id:        room_id,
          message_prefix: payload[:prefix],
          message:        payload[:message],
          color:          color,
          notify:         !payload[:is_success]
        }
        room_notification = RoomNotification.create!(notification_params)

        HipchatPublisher.create!
        |> HipchatPublisher.send_notification(%{room_notification: room_notification})
      else
        result
      end
    end
  end
end
