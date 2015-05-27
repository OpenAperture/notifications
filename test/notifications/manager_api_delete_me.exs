defmodule OpenAperture.ManagerApiTest do
  use ExUnit.Case
  alias OpenAperture.ManagerApi
  alias ManagerApi.MessagingBroker
  alias ManagerApi.MessagingExchange
  alias OpenAperture.Messaging.ConnectionOptionsResolver
  alias OpenAperture.Notifications.Configuration

  test "start" do
    Application.ensure_started(:openaperture_manager_api)
    api = ManagerApi.create!(%{
      # manager_url: "https://openaperture-mgr.psft.co",
      manager_url: "https://openaperture-mgr-staging.psft.co",
      oauth_login_url: "https://auth.psft.co/oauth/token",
      oauth_client_id: "1b579078212937c818626d8740361321e2f4521622adfc6fc3b4e52e42047a9e",
      oauth_client_secret: "84b90f57cb4be305dc4e341597a7e5c7b4677cea44e8eac3cb93daf1e8d21d8e"
    })

    # options = OpenAperture.Messaging.ConnectionOptionsResolver.get_for_broker(api, Configuration.get_current_broker_id)
    # ConnectionOptionsResolver.get_for_broker(api, 3) |> IO.inspect

    # MessagingBroker.create_broker!(api, %{name: "localhost"}) |> IO.inspect
    MessagingBroker.create_broker_connection!(api, 3, %{virtual_host: "/", username: "guest", password: "guest", host: "localhost"}) |> IO.inspect
    # MessagingBroker.broker_connections!(api, 3) |> IO.inspect
    # MessagingBroker.list!(api) |> IO.inspect
    # MessagingBroker.delete_broker_connections!(api, 3) |> IO.inspect
    # MessagingBroker.update

  end
end
