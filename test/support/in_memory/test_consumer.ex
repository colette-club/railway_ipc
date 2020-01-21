defmodule RailwayIpc.InMemory.TestConsumer do
  @moduledoc false

  require Logger

  use RailwayIpc.Consumer, broker: RailwayIpc.InMemory.TestBroker

  alias RailwayIpc.TestHelpers

  def handle_message(%Events.AThingWasDone{context: %{"parent" => parent}}, %{
        correlation_id: correlation_id
      }) do
    parent = TestHelpers.deserialize(parent)

    response =
      Events.AThingWasDone.new(
        context: %{"result" => "here"},
        user_uuid: "123",
        correlation_id: correlation_id
      )

    send(parent, {__MODULE__, Events.AThingWasDone, correlation_id})

    {:ok, response}
  end
end
