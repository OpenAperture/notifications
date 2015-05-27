defmodule OpenAperture.Notifications.DispatcherTests do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias OpenAperture.Notifications.Dispatcher
  alias OpenAperture.Notifications.Hipchat.Room
  alias OpenAperture.Notifications.Hipchat.AuthToken
  alias OpenAperture.Notifications.Hipchat.Publisher, as: HipchatPublisher
  alias OpenAperture.Notifications.Hipchat.RoomNotification

  alias OpenAperture.Messaging.Queue
  alias OpenAperture.Messaging.ConnectionOptions
  alias OpenAperture.Messaging.AMQP.ConnectionOptions
  alias OpenAperture.Messaging.AMQP.ConnectionPool
  alias OpenAperture.Messaging.AMQP.ConnectionPools
  alias OpenAperture.Messaging.AMQP.SubscriptionHandler
  alias OpenAperture.Messaging.ConnectionOptionsResolver
  alias OpenAperture.Messaging.AMQP.QueueBuilder
  alias OpenAperture.Messaging.AMQP.ConnectionOptions, as: AMQPConnectionOptions

  alias OpenAperture.Notifications.Mailer
  setup_all do
    Room.start_link
    AuthToken.start_link
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes", "fixture/custom_cassettes")
    Mailman.TestServer.start && :ok
    :ok
  end

  # ===================================
  # register_queues tests

  test "register_queues success" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn _ -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn _, _, _, _ -> :ok end)

    :meck.new(ConnectionOptionsResolver, [:passthrough])
    :meck.expect(ConnectionOptionsResolver, :get_for_broker, fn _, _ -> %AMQPConnectionOptions{} end)

    :meck.new(QueueBuilder, [:passthrough])
    :meck.expect(QueueBuilder, :build, fn _,_,_ -> %OpenAperture.Messaging.Queue{name: ""} end)

    assert Dispatcher.register_queues == :ok
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
    :meck.unload(ConnectionOptionsResolver)
    :meck.unload(QueueBuilder)
  end

  test "register_queues failure" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn _ -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn _, _, _, _ -> {:error, "bad news bears"} end)

    :meck.new(ConnectionOptionsResolver, [:passthrough])
    :meck.expect(ConnectionOptionsResolver, :get_for_broker, fn _, _ -> %AMQPConnectionOptions{} end)

    :meck.new(QueueBuilder, [:passthrough])
    :meck.expect(QueueBuilder, :build, fn _,_,_ -> %OpenAperture.Messaging.Queue{name: ""} end)

    assert Dispatcher.register_queues == {:error, "bad news bears"}
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
    :meck.unload(ConnectionOptionsResolver)
    :meck.unload(QueueBuilder)
  end

  # ===================================
  # send_hipchat_notifications tests

  test "send_hipchat_notification" do
    :meck.new(SubscriptionHandler, [:passthrough])
    :meck.expect(SubscriptionHandler, :acknowledge, fn _, _ -> :ok end)
    :meck.new(Room, [:passthrough])
    :meck.expect(Room, :resolve_room_ids, fn _ -> [123] end)

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
    Dispatcher.send_hipchat_notifications(payload)
  after
    :meck.unload(Room)
    :meck.unload(HipchatPublisher)
    :meck.unload(SubscriptionHandler)
  end

  test "send_emails() hits Mailman" do
    :meck.new(Mailer)
    :meck.expect(Mailer, :deliver, fn _,_,_ -> "Test Email" end)

    assert %{
      prefix: "[Test]",
      message: "Test message",
      notifications: %{email_addresses: ["email"]}
    } |> Dispatcher.send_emails == "Test Email"
  after
    :meck.unload(Mailer)
  end
end
