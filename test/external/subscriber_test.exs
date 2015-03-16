defmodule CloudOS.Notifications.SubscribeTest do
  use ExUnit.Case
  @moduletag :external

  alias CloudOS.Notifications.Hipchat.Room
  alias CloudOS.Notifications.Hipchat.AuthToken
  alias CloudOS.Notifications.Hipchat.Publisher
  alias CloudOS.Notifications.Hipchat.RoomNotification
  alias CloudOS.Notifications.Dispatcher

  test "subscribe" do
  	CloudOS.Messaging.AMQP.ConnectionPools.start_link
    Room.start_link
    AuthToken.start_link  

    {result, pid} = Dispatcher.start_link
    assert result == :ok
    assert is_pid pid

  	:timer.sleep(30000)
  end 
end