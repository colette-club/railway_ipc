defmodule RailwayIpc.RabbitMQTest do
  use ExUnit.Case, async: true

  @moduletag :rabbitmq

  alias RailwayIpc.RabbitMQ.TestBroker
  alias RailwayIpc.RabbitMQ.TestPublisher

  @spec serialize(term) :: binary
  def serialize(term) do
    term
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end

  setup do
    start_supervised(TestBroker.child_spec([]), restart: :temporary)

    :ok
  end

  test "publishes a message on a queue" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert :ok = TestPublisher.publish(message, routing_key: "test:messages")
    assert_receive {RailwayIpc.RabbitMQ.TestConsumer, Events.AThingWasDone, ^correlation_id}
  end

  test "publishes a message on a queue and waits for an answer" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert {:ok, %Events.AThingWasDone{context: %{"result" => "here"}, correlation_id: ^correlation_id, user_uuid: "123", uuid: ""}} = TestPublisher.publish_sync(message, routing_key: "test:messages")
    assert_receive {RailwayIpc.RabbitMQ.TestConsumer, Events.AThingWasDone, ^correlation_id}
  end
end
