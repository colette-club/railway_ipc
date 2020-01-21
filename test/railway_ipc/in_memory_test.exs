defmodule RailwayIpc.InMemoryTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.InMemory.TestBroker
  alias RailwayIpc.InMemory.TestPublisher
  alias RailwayIpc.TestHelpers

  setup do
    start_supervised(TestBroker.child_spec([]), restart: :temporary)

    :ok
  end

  test "publishes a message" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => TestHelpers.serialize(pid)}
      )

    assert :ok = TestPublisher.publish(message, consumer: RailwayIpc.InMemory.TestConsumer)
    assert_receive {RailwayIpc.InMemory.TestConsumer, Events.AThingWasDone, ^correlation_id}
  end

  test "publishes a message and waits for an answer" do
    pid = self()
    correlation_id = UUID.uuid4()

    message =
      Events.AThingWasDone.new(
        user_uuid: UUID.uuid4(),
        correlation_id: correlation_id,
        uuid: UUID.uuid4(),
        context: %{"parent" => TestHelpers.serialize(pid)}
      )

    assert {:ok,
            %Events.AThingWasDone{
              context: %{"result" => "here"},
              correlation_id: ^correlation_id
            }} = TestPublisher.publish_sync(message, consumer: RailwayIpc.InMemory.TestConsumer)

    assert_receive {RailwayIpc.InMemory.TestConsumer, Events.AThingWasDone, ^correlation_id}
  end
end
