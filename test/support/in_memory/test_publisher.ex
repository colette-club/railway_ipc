defmodule RailwayIpc.InMemory.TestPublisher do
  @moduledoc false
  use RailwayIpc.Publisher, broker: RailwayIpc.InMemory.TestBroker
end
