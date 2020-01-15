defmodule RailwayIpc.RabbitMQ.TestTopicPublisher do
  @moduledoc false
  use RailwayIpc.Publisher, broker: RailwayIpc.RabbitMQ.TestBroker, exchange: "railway_ipc.topic"
end
