defmodule RailwayIpc.RabbitMQ.TestConsumer do
  @moduledoc false

  require Logger
  use RailwayIpc.Consumer, broker: RailwayIpc.RabbitMQ.TestBroker, queue_name: "test:messages"

  @spec deserialize(binary) :: term
  def deserialize(str) when is_binary(str) do
    str
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end

  def handle_message(%Events.AThingWasDone{context: %{"parent" => parent}}, %{correlation_id: correlation_id}) do
    parent = deserialize(parent)
    response = Events.AThingWasDone.new(context: %{"result" => "here"}, user_uuid: "123", correlation_id: correlation_id)

    send(parent, {__MODULE__, Events.AThingWasDone, correlation_id})

    {:ok, response}
  end
end
