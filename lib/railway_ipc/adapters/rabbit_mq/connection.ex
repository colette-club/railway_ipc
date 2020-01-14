defmodule RailwayIpc.Adapters.RabbitMQ.Connection do
  @moduledoc false

  @default_pool_size 5

  @doc """
  Returns the child spec for the connection

  It uses ex_rabbit_pool
  """
  def child_spec(opts \\ []) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    rabbitmq_config =
      Keyword.take(opts, [
        :username,
        :password,
        :virtual_host,
        :host,
        :port,
        :channel_max,
        :frame_max,
        :heartbeat,
        :connection_timeout,
        :ssl_options,
        :client_properties,
        :socket_options
      ])

    publishers_pool_size = Keyword.get(opts, :publishers_pool_size, @default_pool_size)
    consumers_pool_size = Keyword.get(opts, :consumers_pool_size, @default_pool_size)

    publishers_conn_pool = [
      name: {:local, pool_name(:publishers, otp_app)},
      worker_module: ExRabbitPool.Worker.RabbitConnection,
      size: publishers_pool_size,
      max_overflow: 0
    ]

    consumers_conn_pool = [
      name: {:local, pool_name(:consumers, otp_app)},
      worker_module: ExRabbitPool.Worker.RabbitConnection,
      size: consumers_pool_size,
      max_overflow: 0
    ]

    %{
      id: ExRabbitPool.PoolSupervisor,
      start:
        {ExRabbitPool.PoolSupervisor, :start_link,
         [
           [
             rabbitmq_config: rabbitmq_config,
             connection_pools: [publishers_conn_pool, consumers_conn_pool]
           ],
           supervisor_name(otp_app)
         ]}
    }
  end

  @spec pool_name(type :: atom(), opts_or_otp_app :: Keyword.t() | atom()) :: atom()
  def pool_name(type, opts) when is_list(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    pool_name(type, otp_app)
  end

  def pool_name(type, otp_app) when is_atom(otp_app) do
    String.to_atom("#{otp_app}_#{type}_pool")
  end

  def supervisor_name(otp_app) do
    String.to_atom("#{otp_app}.ExRabbitPool.PoolSupervisor")
  end

  def with_connection(type, opts, fun) do
    exchange = Keyword.get(opts, :exchange, "")
    routing_key = Keyword.get(opts, :routing_key, "")

    pool_name(type, opts)
    |> ExRabbitPool.with_channel(fn {:ok, channel} ->
      fun.(channel, exchange, routing_key)
    end)
  end
end
