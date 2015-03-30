defmodule CloudOS.Notifications.DispatcherTests do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias CloudOS.Notifications.Dispatcher
  alias CloudOS.Notifications.Hipchat.Room
  alias CloudOS.Notifications.Hipchat.AuthToken
  alias CloudOS.Notifications.Hipchat.Publisher, as: HipchatPublisher
  alias CloudOS.Notifications.Hipchat.RoomNotification

  alias CloudOS.Messaging.Queue
  alias CloudOS.Messaging.ConnectionOptions
  alias CloudOS.Messaging.AMQP.ConnectionOptions
  alias CloudOS.Messaging.AMQP.ConnectionPool
  alias CloudOS.Messaging.AMQP.ConnectionPools
  alias CloudOS.Messaging.AMQP.Exchange, as: AMQPExchange
  alias CloudOS.Messaging.AMQP.SubscriptionHandler
  
	setup_all do
    Room.start_link
    AuthToken.start_link    
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes", "fixture/custom_cassettes")
    :ok
  end

  # ===================================
  # register_queues tests

  test "register_queues success" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn opts -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn pool, exchange, queue, callback -> :ok end)

    assert Dispatcher.register_queues == :ok
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
  end

  test "register_queues failure" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn opts -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn pool, exchange, queue, callback -> {:error, "bad news bears"} end)

    assert Dispatcher.register_queues == {:error, "bad news bears"}
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
  end

  # ===================================
  # register_queues tests

  test "dispatch_hipchat_notification" do
    :meck.new(SubscriptionHandler, [:passthrough])
    :meck.expect(SubscriptionHandler, :acknowledge, fn _, _ -> :ok end)
    :meck.new(Room, [:passthrough])
    :meck.expect(Room, :resolve_room_ids, fn names -> [123] end)

    prefix = "prefix"
    message = "test message"
    is_success = true
    :meck.new(HipchatPublisher, [:passthrough])
    :meck.expect(HipchatPublisher, :send_notification, fn publisher, options -> 
      assert publisher != nil
      assert options != nil
      notification = options[:room_notification]

      assert is_pid notification
      notification_options = RoomNotification.options(notification)
      assert notification_options != nil

      assert notification_options[:room_id] == 123
      assert notification_options[:color] == "green"
      assert notification_options[:notify] == false
      assert notification_options[:message] != nil
      assert String.contains?(notification_options[:message], prefix)

      :ok 
    end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn pool, exchange, queue, callback -> :ok end)

    payload = %{
      prefix: prefix,
      message: message,
      is_success: true
    }
    Dispatcher.dispatch_hipchat_notification(payload, %{subscription_handler: %{}, delivery_tag: "123abc"})
  after
    :meck.unload(Room)
    :meck.unload(HipchatPublisher)
    :meck.unload(SubscriptionHandler)
  end
end
