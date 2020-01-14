defmodule RailwayIpc.ConsumerTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Consumer
  alias RailwayIpc.Payload

  describe "process/4" do
    test "delegates the decoded message handling to the provided module and calls the ack_func" do
      correlation_id = UUID.uuid4()

      message =
        Events.AThingWasDone.new(
          user_uuid: "abcabc",
          uuid: UUID.uuid4(),
          correlation_id: correlation_id
        )

      {:ok, encoded_message} = Payload.encode(message)
      metadata = %{parent: self()}

      ack_func = fn ->
        send(self(), {:ack_func, correlation_id})
      end

      assert :ok =
               Consumer.process(
                 encoded_message,
                 metadata,
                 RailwayIpc.TestConsumer,
                 ack_func
               )

      assert_received {RailwayIpc.TestConsumer, :handle_message, ^message, ^metadata}
      assert_received {:ack_func, ^correlation_id}
    end

    test "does not ack the message if the message handler returns an error" do
      correlation_id = UUID.uuid4()

      message =
        Events.FailedToDoAThing.new(
          user_uuid: "qerds",
          uuid: UUID.uuid4(),
          correlation_id: correlation_id
        )

      {:ok, encoded_message} = Payload.encode(message)
      metadata = %{parent: self()}

      ack_func = fn ->
        send(self(), {:ack_func, correlation_id})
      end

      assert {:error, "error"} =
               Consumer.process(
                 encoded_message,
                 metadata,
                 RailwayIpc.TestConsumer,
                 ack_func
               )

      assert_received {RailwayIpc.TestConsumer, :handle_message, ^message, ^metadata}
      refute_received {:ack_func, ^correlation_id}
    end
  end
end
