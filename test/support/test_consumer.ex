defmodule RailwayIpc.TestConsumer do
  @moduledoc false
  use RailwayIpc.Consumer, broker: RailwayIpc.TestBroker, queue_name: "default:messages"

  def handle_message(%Events.FailedToDoAThing{} = message, %{parent: parent} = metadata) do
    send(parent, {__MODULE__, :handle_message, message, metadata})
    {:error, "error"}
  end

  def handle_message(message, %{parent: parent} = metadata) do
    send(parent, {__MODULE__, :handle_message, message, metadata})
    :ok
  end
end
