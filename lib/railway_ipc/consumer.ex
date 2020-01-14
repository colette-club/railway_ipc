defmodule RailwayIpc.Consumer do
  @moduledoc false

  require Logger

  alias RailwayIpc.Payload

  @callback handle_message(payload :: any(), metadata :: any()) ::
              :ok | {:ok, response :: any()} | {:error, error :: binary()}
  @callback consumer_registered(state :: map(), info :: any()) ::
              :ok | {:error, error :: binary()}
  @callback consumer_unexpectedly_cancelled(state :: map(), info :: any()) ::
              :ok | {:error, error :: binary()}
  @callback consumer_cancelled(state :: map(), info :: any()) ::
              :ok | {:error, error :: binary()}

  @spec process(
          encoded_payload :: binary(),
          metadata :: map(),
          module :: module(),
          ack_func :: function()
        ) :: :ok | {:ok, response :: any()} | {:error, error :: binary()}
  def process(payload, metadata, module, ack_func) do
    case Payload.decode(payload) do
      {:ok, message} ->
        module.handle_message(message, metadata)
        |> post_processing(ack_func)

      {:error, error} ->
        Logger.error("Failed to process message #{payload}, error #{error}")
        {:error, error}
    end
  end

  defp post_processing(:ok, ack_func) do
    ack_func.()
    :ok
  end

  defp post_processing({:ok, result}, ack_func) do
    ack_func.()
    {:ok, result}
  end

  defp post_processing({:error, error}, _ack_func) do
    Logger.error("Failed to process message. Error #{error}")
    {:error, error}
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {otp_app, adapter} = RailwayIpc.Consumer.Supervisor.compile_time_config(opts)

      @behaviour RailwayIpc.Consumer

      @opts opts
      @otp_app otp_app
      @adapter adapter

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        RailwayIpc.Consumer.Supervisor.start_link(__MODULE__, @otp_app, @adapter, @opts, opts)
      end

      def handle_message(_payload, _metadata), do: :ok
      def consumer_registered(_state, _info), do: :ok
      def consumer_unexpectedly_cancelled(_state, _info), do: :ok
      def consumer_cancelled(_state, _info), do: :ok

      defoverridable handle_message: 2
      defoverridable consumer_registered: 2
      defoverridable consumer_unexpectedly_cancelled: 2
      defoverridable consumer_cancelled: 2
    end
  end
end
