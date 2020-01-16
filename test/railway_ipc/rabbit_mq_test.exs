defmodule RailwayIpc.RabbitMQTest do
  use ExUnit.Case, async: true

  @moduletag :rabbitmq

  alias RailwayIpc.RabbitMQ.TestBroker
  alias RailwayIpc.RabbitMQ.TestPublisher
  alias RailwayIpc.RabbitMQ.TestTopicPublisher

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

  test "publishes a message on a direct exchange" do
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

  test "publishes a message on a direct exchange and waits for an answer" do
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

  test "publishes a message on an inexistent exchange" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert :ok = TestPublisher.publish(message, exchange: "unknown", routing_key: "unknown:messages")
    assert :ok = TestPublisher.publish(message, exchange: "unknown", routing_key: "unknown:messages", mandatory: true)
  end

  test "publishes a message on a topic exchange" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert :ok = TestPublisher.publish(message, exchange: "railway_ipc.topic", routing_key: "test.thing.done")
    assert_receive {RailwayIpc.RabbitMQ.TestTopicConsumer, Events.AThingWasDone, ^correlation_id}
  end

  test "publishes a message on a topic exchange and waits for an answer" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert {:ok, %Events.AThingWasDone{context: %{"result" => "here is the result from the topic consumer"}, correlation_id: ^correlation_id, user_uuid: "123", uuid: ""}} = TestPublisher.publish_sync(message, exchange: "railway_ipc.topic", routing_key: "test.thing.done")
    assert_receive {RailwayIpc.RabbitMQ.TestTopicConsumer, Events.AThingWasDone, ^correlation_id}
  end

  test "publishes a message on a topic exchange with a publisher that defines a default exchange" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => serialize(pid)}
      )

    assert :ok = TestTopicPublisher.publish(message, routing_key: "test.thing.done")
    assert_receive {RailwayIpc.RabbitMQ.TestTopicConsumer, Events.AThingWasDone, ^correlation_id}
  end
end
