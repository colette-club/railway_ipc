defmodule RailwayIpc.Ipc.RepublishedMessagesPublisher do
  use RailwayIpc.Publisher,
    queue: "railway_ipc:republished_messages:commands"

  alias RailwayIpc.Ipc.RepublishedMessageAdapter, as: DataAdapter
  alias RailwayIpc.Ipc.Logger, as: IpcLogger
  require Logger

  def invoke_republish_message(
        published_message_uuid,
        %{correlation_id: correlation_id, current_user: %{learn_uuid: learn_uuid}} = request_data
      ) do
    case DataAdapter.republish_message(published_message_uuid, request_data) do
      {:ok, protobuf} ->
        IpcLogger.log_republishing_message(protobuf)
        direct_publish(protobuf)

      {:error, _error} = e ->
        Logger.error(
          "Failed to republish message with UUID: #{published_message_uuid}. Error: #{inspect(e)}",
          feature: "ipc_republish_message",
          learn_uuid: learn_uuid,
          correlation_id: correlation_id
        )

        e
    end
  end
end
