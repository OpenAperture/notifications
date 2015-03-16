# CloudOS.Notifications

The Notifications module provides a standardized mechanism to publish events that occur within CloudOS.  The following notification providers are supported:

* HipChat

## HipChat Notifications

Requests to publish HipChat notifications may be sent to the following queue:

* notifications_hipchat

The message payload must conform to the following contract:

* Required Parameters:
	* message - String containing the body of the message.
	* is_success - Boolean.  If true, the message background will be set to green and no HipChat notifications will be generated.  False will set the message background to red and a HipChat notification will be generated.
* Optional Parameters:
	* room_names - List of Strings, each string containing the name of a HipChat room to which to publish the message.  The default room (defined in the module configuration) does not need to be specified.
	* prefix - String containing a prefix for the message.  A timestamp (UTC) will be prepended automatically to the message, or this prefix value.

Here's an example payload:
```json
%{
  prefix: "Testing",
  message: "This is a test of the Notifications module",
  is_success: true
}
```

This payload will generate a message looking like this:

```
Fri, 13 Mar 2015 19:17:25 UTC Testing: This is a test of the Notifications module
```

## Module Configuration

The following configuration values must be defined either as environment variables or as part of the environment configuration files:

* AMQP Username
	* Type:  String
	* Description:  The username for the AMQP connection
  * Environment Variable:  MESSAGING_USERNAME
  * Environment Configuration (<env>.exs):  :cloudos_messaging, :username
* AMQP Password
	* Type:  String
	* Description:  The password for the AMQP connection
  * Environment Variable:  MESSAGING_PASSWORD
  * Environment Configuration (<env>.exs):  :cloudos_messaging, :password
* AMQP Host
	* Type:  String
	* Description:  The host for the AMQP connection
  * Environment Variable:  MESSAGING_HOST
  * Environment Configuration (<env>.exs):  :cloudos_messaging, :host
* AMQP Virtual Host
	* Type:  String
	* Description:  The virtual host for the AMQP connection
  * Environment Variable:  MESSAGING_VIRTUAL_HOST
  * Environment Configuration (<env>.exs):  :cloudos_messaging, :virtual_host
* AMQP Exchange
	* Type:  String
	* Description:  The exchange for the AMQP connection
  * Environment Variable:  MESSAGING_EXCHANGE
  * Environment Configuration (<env>.exs):  :cloudos_messaging, :exchange
* HipChat Authentication Tokens
	* Type:  Comma delimited string (no spaces)
	* Description:  A comma delimited string of [HipChat authentication tokens](https://www.hipchat.com/docs/apiv2/auth), used for publishing messages to HipChat.
  * Environment Variable:  HIPCHAT_AUTH_TOKENS
  * Environment Configuration (<env>.exs):  :hipchat, :auth_tokens
* HipChat Authentication Tokens
	* Type:  String
	* Description:  A default room name must be configured as part of the module, to ensure that all messages are published somewhere.
  * Environment Variable:  HIPCHAT_DEFAULT_ROOM_NAME
  * Environment Configuration (<env>.exs):  :hipchat, :default_room_name

## Building & Testing

### Building

The normal elixir project setup steps are required:

```iex
mix do deps.get, deps.compile
```

To startup the application, use mix run:

```iex
MIX_ENV=prod elixir --sname notifications -S mix run --no-halt
```

### Testing 

You can then run the tests

```iex
MIX_ENV=test mix test test/
```

If you want to run the RabbitMQ system tests (i.e. hit a live system):

1.  Define a new configuration for the "system" environment (config/system.exs) with the following contents:

```
config :cloudos_messaging,
  username: "user",
  password: "pass",
  virtual_host: "env",
  host: "host.myrabbit.com"

config :hipchat,
  auth_tokens: "123abc,789xyz",
  default_room_name: "Events"

config :logger, :console,
  level: :debug
```

2.  Run the following commands on separate machines, able to access the RabbitMQ server:

```iex
MIX_ENV=system mix test test/external/publisher_test.exs --include external:true

MIX_ENV=system mix test test/external/subscriber_test.exs --include external:true
```