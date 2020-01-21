defmodule RailwayIpc.PublisherTest do
  use ExUnit.Case

  alias RailwayIpc.Payload

  defp normalize(config) do
    config |> Enum.sort()
  end

  describe "RailwayIpc.Publisher.publish/3" do
    test "calls the adapter with a binary payload and the opts" do
      message =
        Events.AThingWasDone.new(
          user_uuid: "abcabc",
          uuid: UUID.uuid4(),
          correlation_id: UUID.uuid4()
        )

      parent = self()

      assert :ok =
               RailwayIpc.Publisher.publish(RailwayIpc.TestAdapter, message,
                 parent: parent,
                 foo: :bar
               )

      {:ok, expected_payload} =
        message
        |> Payload.prepare()
        |> Payload.encode()

      assert is_binary(expected_payload)

      expected_metadata =
        message
        |> Payload.prepare()
        |> Payload.metadata()

      assert is_map(expected_metadata)

      assert_receive {RailwayIpc.TestAdapter, :publish, ^expected_payload, ^expected_metadata,
                      opts}

      assert [foo: :bar, parent: ^parent] = normalize(opts)
    end
  end

  describe "RailwayIpc.Publisher.publish_sync/3" do
    test "calls the adapter with a binary payload and the opts" do
      message =
        Events.AThingWasDone.new(
          user_uuid: "abcabc",
          uuid: UUID.uuid4(),
          correlation_id: UUID.uuid4()
        )

      parent = self()

      assert {:ok, %{publish_sync_response: :bar}} =
               RailwayIpc.Publisher.publish_sync(RailwayIpc.TestAdapter, message,
                 parent: parent,
                 foo: :bar
               )

      {:ok, expected_payload} =
        message
        |> Payload.prepare()
        |> Payload.encode()

      assert is_binary(expected_payload)

      expected_metadata =
        message
        |> Payload.prepare()
        |> Payload.metadata()

      assert is_map(expected_metadata)

      assert_receive {RailwayIpc.TestAdapter, :publish_sync, ^expected_payload,
                      ^expected_metadata, opts}

      assert [foo: :bar, parent: ^parent] = normalize(opts)
    end
  end

  describe "publish/2" do
    test "calls RailwayIpc.Publisher.publish/3 with the broker options" do
      message =
        Events.AThingWasDone.new(
          user_uuid: "abcabc",
          uuid: UUID.uuid4(),
          correlation_id: UUID.uuid4()
        )

      parent = self()

      assert :ok = RailwayIpc.TestPublisher.publish(message, parent: parent, foo: :bar)

      assert_receive {RailwayIpc.TestAdapter, :publish, payload, metadata, opts}

      assert is_binary(payload)
      assert is_map(metadata)

      assert [broker: RailwayIpc.TestBroker, foo: :bar, otp_app: :railway_ipc, parent: ^parent] =
               normalize(opts)

      assert RailwayIpc.TestBroker.__adapter__() == RailwayIpc.TestAdapter
    end
  end

  describe "publish_sync/2" do
    test "calls RailwayIpc.Publisher.publish_sync/3 with the broker options" do
      message =
        Events.AThingWasDone.new(
          user_uuid: "abcabc",
          uuid: UUID.uuid4(),
          correlation_id: UUID.uuid4()
        )

      parent = self()

      assert {:ok, %{publish_sync_response: :bar}} =
               RailwayIpc.TestPublisher.publish_sync(message, parent: parent, foo: :bar)

      assert_receive {RailwayIpc.TestAdapter, :publish_sync, payload, metadata, opts}

      assert is_binary(payload)
      assert is_map(metadata)

      assert [broker: RailwayIpc.TestBroker, foo: :bar, otp_app: :railway_ipc, parent: ^parent] =
               normalize(opts)

      assert RailwayIpc.TestBroker.__adapter__() == RailwayIpc.TestAdapter
    end
  end
end
