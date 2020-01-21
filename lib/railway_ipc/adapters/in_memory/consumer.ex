defmodule RailwayIpc.Adapters.InMemory.Consumer do
  @moduledoc false

  use GenServer

  @behaviour RailwayIpc.Consumer.Impl

  @impl true
  def child_spec(opts) do
    module = Keyword.fetch!(opts, :module)
    name = Keyword.fetch!(opts, :name)

    [
      %{
        id: name,
        start:
          {__MODULE__, :start_link,
           [
             [
               module: module
             ],
             name
           ]}
      }
    ]
  end

  def start_link(config, name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @impl true
  def init(config) do
    module = Keyword.fetch!(config, :module)
    {:ok, %{module: module}}
  end

  @impl true
  def handle_cast({:publish, payload, metadata, _opts}, %{module: module} = state) do
    ack_func = fn -> :ok end

    RailwayIpc.Consumer.process(payload, metadata, module, ack_func)

    {:noreply, state}
  end

  @impl true
  def handle_call({:publish_sync, payload, metadata, _opts}, _from, %{module: module} = state) do
    ack_func = fn -> :ok end

    result = RailwayIpc.Consumer.process(payload, metadata, module, ack_func)

    {:reply, result, state}
  end
end
