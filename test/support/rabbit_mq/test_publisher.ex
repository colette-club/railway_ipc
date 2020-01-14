defmodule RailwayIpc.RabbitMQ.TestPublisher do
  @moduledoc false
  use RailwayIpc.Publisher, broker: RailwayIpc.RabbitMQ.TestBroker
end
