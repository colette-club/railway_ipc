defmodule RailwayIpc.TestPublisher do
  @moduledoc false

  use RailwayIpc.Publisher, broker: RailwayIpc.TestBroker
end
