defmodule RailwayIpc.Adapters.RabbitMQ.Consumer do
  @moduledoc false

  use ExRabbitPool.Consumer

  alias RailwayIpc.Adapters.RabbitMQ
  alias RailwayIpc.Payload

  @behaviour RailwayIpc.Consumer.Impl

  @impl true
  def validate_config!(config) do
    queue_name = config[:queue_name]

    unless queue_name do
      raise ArgumentError,
            "missing :queue_name option on use RailwayIpc.Consumer with RabbitMQ adapter"
    end

    :ok
  end

  @impl true
  def child_spec(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    queue_name = Keyword.fetch!(opts, :queue_name)
    module = Keyword.fetch!(opts, :module)
    adapter = Keyword.get(opts, :adapter, RabbitMQ.current_impl())
    queue_initializer = Keyword.get(opts, :queue_initializer, RabbitMQ.QueueInitializer)
    name = Keyword.fetch!(opts, :name)
    name = String.to_atom("#{name}.RabbitMQ")

    pool_id = RabbitMQ.Connection.pool_name(:consumers, otp_app)

    [
      queue_initializer.child_spec(opts),
      %{
        id: name,
        start:
          {__MODULE__, :start_link,
           [
             [
               adapter: adapter,
               pool_id: pool_id,
               queue: queue_name,
               module: module,
               otp_app: otp_app
             ],
             name
           ]}
      }
    ]
  end

  def start_link(config, name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def basic_deliver(
        %{config: config, adapter: adapter, channel: channel},
        payload,
        %{delivery_tag: delivery_tag} = metadata
      ) do
    module = Keyword.fetch!(config, :module)
    otp_app = Keyword.fetch!(config, :otp_app)

    ack_func = fn ->
      :ok = adapter.ack(channel, delivery_tag, requeue: false)
    end

    RailwayIpc.Consumer.process(payload, metadata, module, ack_func)
    |> reply_if_needed(metadata, otp_app)

    :ok
  end

  defp reply_if_needed(
         {:ok, payload},
         %{correlation_id: correlation_id, reply_to: reply_to_queue},
         otp_app
       )
       when is_binary(reply_to_queue) and is_binary(correlation_id) do
    {:ok, encoded_payload} = Payload.encode(payload)

    RabbitMQ.publish(encoded_payload, %{},
      otp_app: otp_app,
      correlation_id: correlation_id,
      routing_key: reply_to_queue
    )
  end

  defp reply_if_needed(_payload, _metadata, _otp_app), do: :ok

  def basic_consume_ok(%{config: config} = state, consumer_tag) do
    module = Keyword.fetch!(config, :module)

    module.consumer_registered(state, %{consumer_tag: consumer_tag})
    |> case do
      :ok -> :ok
      {:error, error} -> {:stop, error}
    end
  end

  def basic_cancel(%{config: config} = state, consumer_tag, no_wait) do
    module = Keyword.fetch!(config, :module)

    module.consumer_unexpectedly_cancelled(state, %{consumer_tag: consumer_tag, no_wait: no_wait})
    |> case do
      :ok -> :ok
      {:error, error} -> {:stop, error}
    end
  end

  def basic_cancel_ok(%{config: config} = state, consumer_tag) do
    module = Keyword.fetch!(config, :module)

    module.consumer_cancelled(state, %{consumer_tag: consumer_tag})
    |> case do
      :ok -> :ok
      {:error, error} -> {:stop, error}
    end
  end
end
