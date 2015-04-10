require Logger

defmodule OpenAperture.Notifications.TestConsumerPub do

	alias OpenAperture.Messaging.Queue
	alias OpenAperture.Messaging.ConnectionOptions
	alias OpenAperture.Messaging.AMQP.ConnectionOptions
	alias OpenAperture.Messaging.AMQP.Exchange, as: AMQPExchange

	@connection_options %OpenAperture.Messaging.AMQP.ConnectionOptions{
		username: Application.get_env(:openaperture_messaging, :username),
		password: Application.get_env(:openaperture_messaging, :password),
		virtual_host: Application.get_env(:openaperture_messaging, :virtual_host),
		host: Application.get_env(:openaperture_messaging, :host)
	}
	use OpenAperture.Messaging

	@queue %Queue{
      name: "notifications_hipchat", 
      exchange: %AMQPExchange{name: Application.get_env(:openaperture_messaging, :exchange), options: [:durable]},
      error_queue: "notifications_error",
      options: [durable: true, arguments: [{"x-dead-letter-exchange", :longstr, ""},{"x-dead-letter-routing-key", :longstr, "notifications_error"}]],
      binding_options: [routing_key: "notifications_hipchat"]
    }

	def send_message(payload) do
		IO.puts("sending message:  #{inspect payload}")
		publish(@queue, payload)
	end
end

defmodule OpenAperture.Notifications.PublishTest do
  use ExUnit.Case
  @moduletag :external

  alias OpenAperture.Notifications.TestConsumerPub

  test "publish" do
  	OpenAperture.Messaging.AMQP.ConnectionPools.start_link

  	hipchat_notification = %{
      prefix: "Testing",
      message: "This is a test of the Notifications module",
      is_success: true
    }
  	send_result = TestConsumerPub.send_message(hipchat_notification)
  	IO.puts("send_result:  #{inspect send_result}")
  	:timer.sleep(30000)
  end 
end
