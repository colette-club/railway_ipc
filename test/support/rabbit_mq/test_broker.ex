defmodule RailwayIpc.RabbitMQ.TestBroker do
  @moduledoc false

  use RailwayIpc.Broker, otp_app: :railway_ipc, adapter: RailwayIpc.Adapters.RabbitMQ

  def init(opts) do
    opts = Keyword.put(opts, :consumers, [RailwayIpc.RabbitMQ.TestConsumer, RailwayIpc.RabbitMQ.TestTopicConsumer])
    {:ok, opts}
  end
end
