defmodule Agents.Notifications.HipchatRoomNotificationTests do
  use ExUnit.Case

  alias OpenAperture.Notifications.Hipchat.RoomNotification

  test "sets defaults" do
    notification = RoomNotification.create!(%{})
    
    assert notification != nil
    options = RoomNotification.options(notification)
    assert options != nil
    assert options[:room_id] == nil
    assert options[:color] == "gray"
    assert options[:message] != nil
    assert options[:notify] == false
    assert options[:message_format] == "html"
  end

  test "override defaults" do
    notification = RoomNotification.create!(%{room_id: "123abc", color: "black", notify: true, message_format: "text"})
    
    assert notification != nil
    options = RoomNotification.options(notification)
    assert options != nil
    assert options[:room_id] == "123abc"
    assert options[:color] == "black"
    assert options[:message] != nil
    assert options[:notify] == true
    assert options[:message_format] == "text"
  end  
end