defmodule RailwayIpc.InMemory.TestBroker do
  @moduledoc false

  use RailwayIpc.Broker, otp_app: :railway_ipc, adapter: RailwayIpc.Adapters.InMemory

  def init(opts) do
    opts = Keyword.put(opts, :consumers, [RailwayIpc.InMemory.TestConsumer])
    {:ok, opts}
  end
end
