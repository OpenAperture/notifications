defmodule OpenAperture.Notifications.SubscribeTest do
  use ExUnit.Case
  @moduletag :external

  alias OpenAperture.Notifications.Hipchat.Room
  alias OpenAperture.Notifications.Hipchat.AuthToken
  alias OpenAperture.Notifications.Hipchat.Publisher
  alias OpenAperture.Notifications.Hipchat.RoomNotification
  alias OpenAperture.Notifications.Dispatcher

  test "subscribe" do
  	OpenAperture.Messaging.AMQP.ConnectionPools.start_link
    Room.start_link
    AuthToken.start_link  

    {result, pid} = Dispatcher.start_link
    assert result == :ok
    assert is_pid pid

  	:timer.sleep(30000)
  end 
end