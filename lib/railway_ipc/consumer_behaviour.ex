defmodule RailwayIpc.ConsumerBehaviour do
  @moduledoc false

  @callback handle_in(protobuf_struct :: map()) :: :ok | {:error, error :: binary()}
end
