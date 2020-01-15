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

## RabbitMQ

The RabbitMQ adapter uses the `ex_rabbit_pool` (https://github.com/esl/ex_rabbit_pool) library to manage the connection pools and
automatically setup the queues on consumer startup according to the provided configuration.

## Usage

TODO

Please, refer to the tests for now.

## Installation

Let's just add this library using github or clone it for now.
