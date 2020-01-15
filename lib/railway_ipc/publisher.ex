defmodule RailwayIpc.Publisher do
  @moduledoc false

  alias RailwayIpc.Payload

  @spec publish(adapter :: module(), protobuf_struct :: map(), opts :: Keyword.t()) ::
          :ok | {:error, error :: binary()}
  def publish(adapter, message, opts \\ []) do
    do_publish(message, opts, &adapter.publish/3)
  end

  @spec publish_sync(adapter :: module(), protobuf_struct :: map(), opts :: Keyword.t()) ::
          {:ok, response :: any()} | {:error, error :: binary()}
  def publish_sync(adapter, message, opts \\ []) do
    do_publish(message, opts, &adapter.publish_sync/3)
  end

  defp do_publish(message, opts, func) do
    message = Payload.prepare(message)
    metadata = Payload.metadata(message)

    {:ok, encoded_message} = Payload.encode(message)
    func.(encoded_message, metadata, opts)
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      broker = Keyword.fetch!(opts, :broker)

      @opts opts
      @adapter broker.__adapter__()
      @otp_app broker.__otp_app__()

      def publish(message, opts \\ []) do
        RailwayIpc.Publisher.publish(@adapter, message, adapter_opts(opts))
      end

      def publish_sync(message, opts \\ []) do
        RailwayIpc.Publisher.publish_sync(@adapter, message, adapter_opts(opts))
      end

      defp adapter_opts(opts) do
        @opts
        |> Keyword.merge(opts)
        |> Keyword.put(:otp_app, @otp_app)
      end
    end
  end
end
