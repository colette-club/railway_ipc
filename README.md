# RailwayIpc

RailwayIpc helps add IPC to an Elixir app. Communication is done via Google's protocol buffers (https://developers.google.com/protocol-buffers). The current version only has one adapter: RabbitMQ.

## Google Protobufs

Messages that are published and consumed with RailwayIpc must respect the Google Protobuf spec.

To use protobufs, define .proto files.  Then, thanks to the `protobuf` and `google_protos`
libraries, generate the corresponding Elixir structs with the following command:

```bash
protoc --proto_path=directory/to/proto/files --elixir_out=output/directory
/directory/to/proto/files/*.proto
```

## Tests

If you need to update the protobufs used in the tests or add new ones, you can use the mix command `mix generate_test_protobufs` to generate the Elixir structs from the `.proto` files.

To run the tests, run `mix test`.

To run the tests that require RabbitMQ, run `mix test --include rabbitmq`. Make sure to start
RabbitMQ before.

## Usage

TODO: Please, refer to the tests for now.

The central piece of the library is the Broker.  A broker must be defined like so

```elixir
defmodule MyApp.Broker do
  use RailwayIpc.Broker, otp_app: :my_app, adapter: RailwayIpc.Adapters.RabbitMQ
end
```

The only required options are `otp_app` and `adapter`.  `otp_app` is used to get the runtime
configuration.  The runtime configuration can be defined in two ways: in the config files or in
the broker `init/1` function.

This is how it looks in the config files

```elixir
config :my_app, MyApp.Broker, host: "localhost", consumers: [MyApp.Consumers.DefaultConsumer]
```

and here is the `init/1` function usage

```elixir
defmodule MyApp.Broker do
  use RailwayIpc.Broker, otp_app: :my_app, adapter: RailwayIpc.Adapters.RabbitMQ

  def init(opts) do
    opts = opts
           |> Keyword.put(:consumers, [MyApp.Consumers.DefaultConsumer])
           |> Keyword.put(:host, "localhost")
    {:ok, opts}
  end
end
```

The optional options only depend on the adapter.  Check the RabbitMQ part of the README to know
more about the specific options.

Finally, make sure to add the broker in your application supervision tree.  You could also specify
runtime options there.

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {MyApp.Broker, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## RabbitMQ

The RabbitMQ adapter uses the `ex_rabbit_pool` (https://github.com/esl/ex_rabbit_pool) library to manage the connection pools and
automatically setup the queues on consumer startup according to the provided configuration.

The optional options you can pass to the broker when the RabbitMQ adapter is used are:
`:username, :password, :virtual_host, :host, :port, :channel_max, :frame_max, :heartbeat, :connection_timeout, :ssl_options, :client_properties, :socket_options` from the `AMQP.Connection.open/2` function and `:consumers`.

Make sure that your consumers are added in the `:consumers` option or else they won't start.

## Installation

Let's just add this library using github or clone it for now.
