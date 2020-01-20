defmodule Mix.Tasks.GenerateTestProtobufs do
  @moduledoc """
  Genereates the test protobufs
  """

  require Logger

  use Mix.Task

  def run(_arg) do
    :os.cmd(
      'protoc --proto_path=test/support/protobuf --elixir_out=test/support/messages test/support/protobuf/*.proto'
    )
    |> case do
      [] ->
        Logger.info("Protobuf messages generated successfully")
      error ->
        Logger.error("Protobuf generation failed with error: #{inspect error}")
    end
  end
end
