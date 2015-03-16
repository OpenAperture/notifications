require Logger

defmodule CloudOS.Notifications.TestConsumerPub do

	alias CloudOS.Messaging.Queue
	alias CloudOS.Messaging.ConnectionOptions
	alias CloudOS.Messaging.AMQP.ConnectionOptions
	alias CloudOS.Messaging.AMQP.Exchange, as: AMQPExchange

	@connection_options %CloudOS.Messaging.AMQP.ConnectionOptions{
		username: Application.get_env(:cloudos_messaging, :username),
		password: Application.get_env(:cloudos_messaging, :password),
		virtual_host: Application.get_env(:cloudos_messaging, :virtual_host),
		host: Application.get_env(:cloudos_messaging, :host)
	}
	use CloudOS.Messaging

	@queue %Queue{
      name: "notifications_hipchat", 
      exchange: %AMQPExchange{name: Application.get_env(:cloudos_messaging, :exchange), options: [:durable]},
      error_queue: "notifications_error",
      options: [durable: true, arguments: [{"x-dead-letter-exchange", :longstr, ""},{"x-dead-letter-routing-key", :longstr, "notifications_error"}]],
      binding_options: [routing_key: "notifications_hipchat"]
    }

	def send_message(payload) do
		IO.puts("sending message:  #{inspect payload}")
		publish(@queue, payload)
	end
end

defmodule CloudOS.Notifications.PublishTest do
  use ExUnit.Case
  @moduletag :external

  alias CloudOS.Notifications.TestConsumerPub

  test "publish" do
  	CloudOS.Messaging.AMQP.ConnectionPools.start_link

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
