defmodule RailwayIpc.Adapters.RabbitMQ do
  @moduledoc false

  @behaviour RailwayIpc.Adapters.Impl

  alias __MODULE__
  alias RailwayIpc.Payload

  @impl true
  @spec child_spec(config :: Keyword.t()) ::
          [:supervisor.child_spec() | {module(), term()} | module()]
  def child_spec(opts \\ []) do
    consumers = Keyword.get(opts, :consumers, [])

    connection_spec = RabbitMQ.Connection.child_spec(opts)
    consumers_spec = Enum.map(consumers, & &1.child_spec(opts))

    [connection_spec | consumers_spec]
  end

  @impl true
  @spec validate_config!(config :: Keyword.t()) :: :ok
  def validate_config!(_config) do
    :ok
  end

  @impl true
  @spec consumer_adapter() :: module()
  def consumer_adapter,
    do: Application.get_env(:railway_ipc, :rabbit_mq_consumer_impl, RabbitMQ.Consumer)

  @impl true
  @spec publish(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
          :ok | {:error, error :: binary()}
  def publish(payload, metadata, opts \\ []) do
    with_connection(opts, fn channel, exchange, routing_key ->
      current_impl().publish(
        channel,
        exchange,
        routing_key,
        payload,
        publish_opts(metadata, opts)
      )
    end)
  end

  @impl true
  @spec publish_sync(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
          {:ok, response :: any()} | {:error, error :: binary()}
  def publish_sync(payload, metadata, opts \\ []) do
    correlation_id = Map.fetch!(metadata, :correlation_id)
    timeout = Keyword.get(opts, :timeout, :timer.seconds(5))

    with_connection(opts, fn channel, exchange, routing_key ->
      {:ok, %{queue: callback_queue}} =
        current_impl().declare_queue(
          channel,
          "",
          exclusive: true,
          auto_delete: true
        )

      opts =
        opts
        |> Keyword.put(:reply_to, callback_queue)

      %Task{pid: task_pid} =
        task =
        Task.async(fn ->
          receive do
            {:basic_deliver, response,
             %{delivery_tag: delivery_tag, correlation_id: ^correlation_id}} ->
              :ok = current_impl().ack(channel, delivery_tag, requeue: false)
              Payload.decode(response)
          after
            timeout ->
              {:error, :timeout}
          end
        end)

      current_impl().consume(channel, callback_queue, task_pid)

      current_impl().publish(
        channel,
        exchange,
        routing_key,
        payload,
        publish_opts(metadata, opts)
      )

      Task.await(task)
    end)
  end

  defp with_connection(opts, fun), do: RabbitMQ.Connection.with_connection(:publishers, opts, fun)

  defp publish_opts(metadata, opts) do
    opts =
      Keyword.take(opts, [
        :mandatory,
        :immediate,
        :content_type,
        :content_encoding,
        :headers,
        :persistent,
        :correlation_id,
        :priority,
        :reply_to,
        :expiration,
        :message_id,
        :timestamp,
        :type,
        :user_id,
        :app_id
      ])

    Keyword.new(metadata)
    |> Keyword.merge(opts, fn _k, v1, _v2 -> v1 end)
  end

  @doc false
  def current_impl do
    Application.get_env(:railway_ipc, :rabbit_mq_client_impl, __MODULE__.Client)
  end
end
