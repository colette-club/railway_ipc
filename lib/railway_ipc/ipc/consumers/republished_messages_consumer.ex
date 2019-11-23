defmodule RailwayIpc.Ipc.RepublishedMessagesConsumer do
  use RailwayIpc.RepublishCommandConsumer,
    queue: "railway_ipc:republished_messages:commands"

  alias RailwayIpc.Ipc.Logger
  alias LearnIpc.Commands.RepublishMessage
  alias RailwayIpc.PublishedMessage

  def handle_in(
        %RepublishMessage{data: %{published_message_uuid: published_message_uuid}} = message
      ) do
    Logger.log_consuming_message(message)

    case PublishedMessage.get(published_message_uuid) do
      nil ->
        {:error, "Unable to find published message with UUID: #{published_message_uuid}"}

      %{message_type: "LearnIpc::Commands::RepublishMessage"} ->
        {:error, "Cannot republish message of type: LearnIpc::Commands::RepublishMessage"}

      %{exchange: nil} ->
        {:error, "Cannot republish message to exchange: nil"}

      published_message ->
        {:emit, published_message}
    end
  end
end
