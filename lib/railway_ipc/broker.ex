defmodule RailwayIpc.Broker do
  @moduledoc """
  Defines a broker.

  The broker expects `:otp_app` and `:adapter` as
  options. The `:otp_app` should point to an OTP application that has
  the repository configuration. For example, the broker:
      defmodule Broker do
        use RailwayIpc.Broker,
          otp_app: :my_app,
          adapter: RailwayIpc.Adapters.RabbitMQ
      end

  could be configured with:
      config :my_app, Broker,
        host: "localhost"
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {otp_app, adapter, _behaviours} = RailwayIpc.Broker.Supervisor.compile_time_config(opts)

      @otp_app otp_app
      @adapter adapter

      def config do
        {:ok, config} =
          RailwayIpc.Broker.Supervisor.runtime_config(__MODULE__, @otp_app, @adapter, [])

        config
      end

      def __adapter__ do
        @adapter
      end

      def __otp_app__ do
        @otp_app
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        RailwayIpc.Broker.Supervisor.start_link(__MODULE__, @otp_app, @adapter, opts)
      end

      def stop(timeout \\ 5000) do
        Supervisor.stop(__MODULE__, :normal, timeout)
      end
    end
  end
end
