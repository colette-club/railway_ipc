defmodule Mix.Tasks.GenerateTestProtobufs do
  @moduledoc """
  Genereates the test protobufs
  """

  use Mix.Task

  def run(_arg) do
    :os.cmd(
      'protoc --proto_path=test/support/protobuf --elixir_out=test/support/messages test/support/protobuf/*.proto'
    )

    IO.puts("Protobuf messages generated successfully")
  end
end
