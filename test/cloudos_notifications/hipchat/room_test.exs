defmodule Agents.Notifications.HipchatRoomTests do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias CloudOS.Notifications.Hipchat.Room
  alias CloudOS.Notifications.Hipchat.AuthToken

	setup_all do
    Room.start_link
    AuthToken.start_link
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes", "fixture/custom_cassettes")
    :ok
  end  

  test "resolve_room_ids - retrieves the ID" do
    use_cassette "hipchat_room_found" do
      room_name = "DevOps"
      assert Room.resolve_room_ids([room_name]) == [12345]
    end
  end

  test "resolve_room_ids - fails to retrieve an ID of non-existing room" do
    use_cassette "hipchat_room_not_found" do
      room_name = "123abc"
      assert Room.resolve_room_ids([room_name]) == []
    end
  end
end
