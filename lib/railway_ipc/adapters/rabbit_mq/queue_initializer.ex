defmodule RailwayIpc.Adapters.RabbitMQ.QueueInitializer do
  @moduledoc """
  Initializes the Queues used by the RabbitMQ consumers
  """

  @defaults [exchange: ""]

  alias RailwayIpc.Adapters.RabbitMQ

  def child_spec(opts \\ []) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    config =
      Keyword.take(opts, [
        :queue_name,
        :exchange,
        :queue_options,
        :exchange_options,
        :bind_options
      ])

    queue_config = Keyword.merge(@defaults, config)
    name = Keyword.fetch!(opts, :name)
    name = String.to_atom("#{name}.QueueInitializer")

    pool_name = RabbitMQ.Connection.pool_name(:consumers, otp_app)

    %{
      id: name,
      start:
        {__MODULE__, :start_link,
         [
           {pool_name, [queues: [queue_config]]},
           name
         ]}
    }
  end

  def start_link(opts, name) do
    GenServer.start_link(ExRabbitPool.Worker.SetupQueue, opts, name: name)
  end
end
