defmodule CloudOS.Notifications.Hipchat.PublisherTests do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias CloudOS.Notifications.Hipchat.Room
  alias CloudOS.Notifications.Hipchat.AuthToken
  alias CloudOS.Notifications.Hipchat.Publisher
  alias CloudOS.Notifications.Hipchat.RoomNotification
  
	setup_all do
    Room.start_link
    AuthToken.start_link    
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes", "fixture/custom_cassettes")
    :ok
  end

  # ===================================
  # handle_cast({:room_notification}) tests

  test "handles success" do
    use_cassette "hipchat_room_notification_success", custom: true do
	    notification = RoomNotification.create!(%{room_id: 12345})

      options = %{room_notification: notification}
      state = %{}
      
      {:noreply, returned_state} = Publisher.handle_cast({:room_notification, options}, state)
      assert returned_state == state
    end
  end

  test "handles failure" do
    use_cassette "hipchat_room_notification_failure", custom: true do
	    notification = RoomNotification.create!(%{room_id: 12345})
      options = %{room_notification: notification}
      state = %{}
      
      {:noreply, returned_state} = Publisher.handle_cast({:room_notification, options}, state)
      assert returned_state == state
    end
  end
end
