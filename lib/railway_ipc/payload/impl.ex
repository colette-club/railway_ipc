defmodule RailwayIpc.Payload.Impl do
  @moduledoc false

  @callback decode(payload :: any()) :: {:ok, message :: map()} | {:error, error :: binary()}
  @callback encode(protobuf_struct :: map()) ::
              {:ok, message :: binary()} | {:error, error :: binary()}
  @callback prepare(protobuf_struct :: map()) :: protobuf_struct :: map()
  @callback metadata(protobuf_struct :: map()) :: metadata :: map()
end
