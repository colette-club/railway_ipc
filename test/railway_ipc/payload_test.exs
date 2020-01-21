defmodule RailwayIpc.PayloadTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Payload

  defmodule InvalidProtobuf do
    defstruct [:foo]
  end

  describe "encode/1" do
    test "properly encodes a protobuf payload" do
      command = Events.AThingWasDone.new(uuid: "123123")
      {:ok, encoded} = Payload.encode(command)

      assert encoded ==
               "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}"
    end

    test "raises an ArgumentError with a map payload" do
      payload = %{message: "Hello", uuid: "d16d4ef8-5304-4954-97e4-a75d6b90988a"}

      assert_raise ArgumentError,
                   "An invalid payload has been provided: %{message: \"Hello\", uuid: \"d16d4ef8-5304-4954-97e4-a75d6b90988a\"}. Please, provide a protobuf payload.",
                   fn -> Payload.encode(payload) end
    end

    test "raises an ArgumentError with a struct that does not have the :encode, :decode and :new functions" do
      payload = %InvalidProtobuf{foo: "d16d4ef8-5304-4954-97e4-a75d6b90988a"}

      assert_raise ArgumentError,
                   "An invalid payload has been provided: %RailwayIpc.PayloadTest.InvalidProtobuf{foo: \"d16d4ef8-5304-4954-97e4-a75d6b90988a\"}. Please, provide a protobuf payload.",
                   fn -> Payload.encode(payload) end
    end

    test "raises an ArgumentError with a binary payload" do
      payload = "hello"

      assert_raise ArgumentError,
                   "An invalid payload has been provided: \"hello\". Please, provide a protobuf payload.",
                   fn -> Payload.encode(payload) end
    end
  end

  describe "decode/1" do
    test "properly decodes message" do
      command = Events.AThingWasDone.new(uuid: "123123")
      {:ok, encoded} = Payload.encode(command)
      {:ok, decoded} = Payload.decode(encoded)

      assert decoded.__struct__ == Events.AThingWasDone
      assert decoded.uuid == "123123"
    end

    test "properly decodes message with whitespace" do
      encoded = "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}\n"
      {:ok, decoded} = Payload.decode(encoded)

      assert decoded.__struct__ == Events.AThingWasDone
    end

    test "when module does not have a :decode function" do
      encoded_payload =
        "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"RailwayIpc.Core.PayloadTest.InvalidProtobuf\"}"

      {:error, reason} = Payload.decode(encoded_payload)
      assert reason == "Unknown message type RailwayIpc.Core.PayloadTest.InvalidProtobuf"
    end

    test "returns an error if given bad JSON" do
      json =
        %{bogus_key: "Banana"}
        |> Jason.encode!()

      {:error, reason} = Payload.decode(json)

      assert reason ==
               "Missing keys in payload: {\"bogus_key\":\"Banana\"}. Expecting type and encoded_message keys"
    end

    test "returns an error if given bad data" do
      {:error, reason} = Payload.decode("")
      assert reason == "Malformed JSON given: "
    end

    test "returns an error if anything other than a string given" do
      {:error, reason} = Payload.decode(123_123)
      assert reason == "Malformed JSON given: 123123. Must be a string"
    end

    test "returns an error if the module is unknown after decoding" do
      json =
        %{type: "BogusModule", encoded_message: ""}
        |> Jason.encode!()

      {:error, reason} = Payload.decode(json)
      assert reason == "Unknown message type BogusModule"
    end
  end

  describe "prepare/1" do
    test "adds UUID and correlation_id when missing" do
      command = Events.AThingWasDone.new()
      assert "" = Map.get(command, :uuid)
      assert "" = Map.get(command, :correlation_id)

      prepared_command = Payload.prepare(command)

      {_, old_values_from_prepared_command} =
        Map.split(prepared_command, [:uuid, :correlation_id])

      {_, old_values_from_command} = Map.split(command, [:uuid, :correlation_id])

      assert old_values_from_command == old_values_from_prepared_command

      assert {:ok, _} = UUID.info(Map.get(prepared_command, :uuid))
      assert {:ok, _} = UUID.info(Map.get(prepared_command, :correlation_id))
    end

    test "does not replace UUID or correlation_id if present" do
      command = Events.AThingWasDone.new(uuid: "my uuid", correlation_id: "my correlation_id")
      assert "my uuid" = Map.get(command, :uuid)
      assert "my correlation_id" = Map.get(command, :correlation_id)

      prepared_command = Payload.prepare(command)

      assert "my uuid" = Map.get(prepared_command, :uuid)
      assert "my correlation_id" = Map.get(prepared_command, :correlation_id)
    end
  end

  describe "metadata/1" do
    test "returns a map containing uuid and correlation_id from the message" do
      command = Events.AThingWasDone.new(uuid: "my uuid", correlation_id: "my correlation_id")
      assert %{uuid: "my uuid", correlation_id: "my correlation_id"} = Payload.metadata(command)
    end
  end
end
