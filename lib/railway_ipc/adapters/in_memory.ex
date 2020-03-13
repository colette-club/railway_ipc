defmodule RailwayIpc.Adapters.InMemory do
  @moduledoc false

  @behaviour RailwayIpc.Adapters.Impl

  alias __MODULE__

  @impl true
  @spec child_spec(config :: Keyword.t()) ::
          [:supervisor.child_spec() | {module(), term()} | module()]
  def child_spec(opts \\ []) do
    consumers = Keyword.get(opts, :consumers, [])
    Enum.map(consumers, & &1.child_spec(opts))
  end

  @impl true
  def consumer_adapter, do: InMemory.Consumer

  @impl true
  @spec publish(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
          :ok | {:error, error :: binary()}
  def publish(payload, metadata, opts \\ []) do
    consumer = Keyword.fetch!(opts, :consumer)

    GenServer.cast(consumer, {:publish, payload, metadata, opts})
  end

  @impl true
  @spec publish_sync(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
          {:ok, response :: any()} | {:error, error :: binary()}
  def publish_sync(payload, metadata, opts \\ []) do
    consumer = Keyword.fetch!(opts, :consumer)

    GenServer.call(consumer, {:publish_sync, payload, metadata, opts})
  end
end
