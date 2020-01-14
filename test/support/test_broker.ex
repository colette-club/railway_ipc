defmodule RailwayIpc.TestConsumerAdapter do
  @moduledoc false

  @behaviour RailwayIpc.Consumer.Impl

  def child_spec(opts) do
    opts[:parent] && send(opts[:parent], {__MODULE__, :child_spec, opts})

    [%{
      id: __MODULE__,
      start:
          {__MODULE__, :start_link,
           [
             opts
           ]}
    }]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(options) do
    {:ok, options}
  end
end

defmodule RailwayIpc.InvalidTestAdapter do
  @moduledoc false
end

defmodule RailwayIpc.TestAdapter do
  @moduledoc false

  @behaviour RailwayIpc.Adapters.Impl

  def child_spec(opts) do
    opts[:parent] && send(opts[:parent], {__MODULE__, :child_spec, opts})
    [Supervisor.child_spec({Task, fn -> :timer.sleep(:infinity) end}, [])]
  end

  def validate_config!(_config), do: :ok

  def consumer_adapter, do: RailwayIpc.TestConsumerAdapter

  def publish(payload, metadata, opts \\ []) do
    opts[:parent] && send(opts[:parent], {__MODULE__, :publish, payload, metadata, opts})
    :ok
  end

  def publish_sync(payload, metadata, opts \\ []) do
    opts[:parent] && send(opts[:parent], {__MODULE__, :publish_sync, payload, metadata, opts})
    {:ok, %{publish_sync_response: :bar}}
  end
end

defmodule RailwayIpc.TestBroker do
  @moduledoc false

  use RailwayIpc.Broker, otp_app: :railway_ipc, adapter: RailwayIpc.TestAdapter

  def init(opts) do
    opts[:parent] && send(opts[:parent], {__MODULE__, :init, opts})
    opts = Keyword.put_new(opts, :host, "localhost")
    {:ok, opts}
  end
end
