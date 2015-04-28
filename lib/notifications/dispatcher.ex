#
# == dispatcher.ex
#
# This module contains the logic to dispatch notification messsages to the appropriate GenServer(s)
#
require Logger

defmodule OpenAperture.Notifications.Dispatcher do
	use GenServer

  alias OpenAperture.Messaging.AMQP.ConnectionOptions, as: AMQPConnectionOptions
  alias OpenAperture.Messaging.AMQP.QueueBuilder
  alias OpenAperture.Messaging.AMQP.SubscriptionHandler

	alias OpenAperture.Notifications.Hipchat.RoomNotification
  alias OpenAperture.Notifications.Hipchat.Room
	alias OpenAperture.Notifications.Hipchat.Publisher, as: HipchatPublisher

  alias OpenAperture.Notifications.Configuration
  alias OpenAperture.Notifications.MessageManager

  alias OpenAperture.ManagerApi

  @moduledoc """
  This module contains the logic to dispatch notification messsages to the appropriate GenServer(s) 
  """  

	@connection_options nil
	use OpenAperture.Messaging

  @doc """
  Specific start_link implementation (required by the supervisor)

  ## Options

  ## Return Values

  {:ok, pid} | {:error, reason}
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
  Method to register the notification queues with the Messaging system

  ## Return Value

  :ok | {:error, reason}
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
        dispatch_hipchat_notification(payload, async_info) 
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
  Method to dispatch HipChat notifications to the HipChat publisher.

  ## Options

  The `payload` option is the Map of HipChat options

  The `_async_info` option defines the Messaging module's asynchronous messaging info

  ## Return Value

  :ok | {:error, reason}
  """
  @spec dispatch_hipchat_notification(Map, Map) :: :ok | {:error, String.t()}
  def dispatch_hipchat_notification(payload, %{subscription_handler: subscription_handler, delivery_tag: delivery_tag} = _async_info) do

    # Until there's a strong usecase for requiring requeue of failed HipChat messages, simply ack/reject here rather than tracking the
    # delivery tags separately.
    try do
    	color = if (payload[:is_success]), do: "green", else: "red"

      default_room = Configuration.get_hipchat_config("HIPCHAT_DEFAULT_ROOM_NAME", :default_room_name)
      room_names = if payload[:room_names] != nil do
        payload[:room_names]
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
            room_id: room_id,
            message_prefix: payload[:prefix],
            message: payload[:message],
            color: color,
            notify: !payload[:is_success]
          }

          case HipchatPublisher.send_notification(HipchatPublisher.create!, %{room_notification: RoomNotification.create!(notification_params)}) do
            :ok -> 
              SubscriptionHandler.acknowledge(subscription_handler, delivery_tag)
              MessageManager.remove(delivery_tag)
              :ok
            {:error, reason} -> 
              SubscriptionHandler.reject(subscription_handler, delivery_tag, false)
              {:error, reason}
          end
        else
          result
        end
      end
    rescue e ->
      error_msg = "An error occurred publishing notification:  #{inspect e}"
      Logger.error(error_msg)
      SubscriptionHandler.reject(subscription_handler, delivery_tag, false)
      MessageManager.remove(delivery_tag)
      {:error, error_msg}
    end      
  end
end