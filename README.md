# OpenAperture.Notifications

[![Build Status](https://semaphoreci.com/api/v1/projects/ec3d79fd-1837-4ace-975a-b860cfc66a7a/395741/badge.svg)](https://semaphoreci.com/perceptive/notifications--2)

The Notifications module provides a standardized mechanism to publish events that occur within OpenAperture.

## Contributing

To contribute to OpenAperture development, view our [contributing guide](http://openaperture.io/dev_resources/contributing.html)

## Module Responsibilities

The Notifications module is responsible for the following actions within OpenAperture:

* Publishing HipChat notifications

## Messaging / Communication

The following message(s) may be sent to Notifications.

* Publish a HipChat Message
  * Queue:  notifications_hipchat
  * Payload (Map)
    * message (required)
      * String containing the body of the message.
    * is_success (required)
      * Boolean.  If true, the message background will be set to green and no HipChat notifications will be generated.  False will set the message background to red and a HipChat notification will be generated.
    * room_names (optional)
      * List of Strings, each string containing the name of a HipChat room to which to publish the message.  The default room (defined in the module configuration) does not need to be specified.
    * prefix (optional)
      * String containing a prefix for the message.  A timestamp (UTC) will be prepended automatically to the message, or this prefix value.

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

* Current Exchange
  * Type:  String
  * Description:  The identifier of the exchange in which Notifications is running
  * Environment Variable:  EXCHANGE_ID
* Current Broker
  * Type:  String
  * Description:  The identifier of the broker to which Notifications is connecting
  * Environment Variable:  BROKER_ID
* Manager URL
  * Type: String
  * Description: The url of the OpenAperture Manager
  * Environment Variable:  MANAGER_URL
  * Environment Configuration (.exs): :openaperture_manager_api, :manager_url
* OAuth Login URL
  * Type: String
  * Description: The login url of the OAuth2 server
  * Environment Variable:  OAUTH_LOGIN_URL
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_login_url
* OAuth Client ID
  * Type: String
  * Description: The OAuth2 client id to be used for authenticating with the OpenAperture Manager
  * Environment Variable:  OAUTH_CLIENT_ID
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_client_id
* OAuth Client Secret
  * Type: String
  * Description: The OAuth2 client secret to be used for authenticating with the OpenAperture Manager
  * Environment Variable:  OAUTH_CLIENT_SECRET
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_client_secret
* Default HipChat Room
  * Type: String
  * Description: The default room for all HipChat messages
  * Environment Variable:  HIPCHAT_DEFAULT_ROOM_NAME
  * Environment Configuration (.exs): :hipchat, :default_room_name

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

Run the following commands on separate machines, able to access the RabbitMQ server:

```iex
MIX_ENV=system mix test test/external/publisher_test.exs --include external:true

MIX_ENV=system mix test test/external/subscriber_test.exs --include external:true
```

## Format of expected MQ messages

%{
  prefix:        "[Some PREFIX]",
  message:       "Some message",
  is_success:    true,
  notifications: %{
    hipchat_rooms:   ["name", "another_name"],
    email_addresses: ["mail@hst.com", "another_mail@hst.com"]
  }
}
