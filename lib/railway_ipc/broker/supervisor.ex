defmodule RailwayIpc.Broker.Supervisor do
  @moduledoc false

  @doc """
  Starts the broker supervisor.
  """
  def start_link(broker, otp_app, adapter, opts) do
    sup_opts = if name = Keyword.get(opts, :name, broker), do: [name: name], else: []
    Supervisor.start_link(__MODULE__, {name, broker, otp_app, adapter, opts}, sup_opts)
  end

  @doc """
  Retrieves the compile time configuration.
  """
  def compile_time_config(opts) do
    otp_app = opts[:otp_app]
    adapter = opts[:adapter]

    unless otp_app do
      raise ArgumentError, "missing :otp_app option on use RailwayIpc.Broker"
    end

    unless adapter do
      raise ArgumentError, "missing :adapter option on use RailwayIpc.Broker"
    end

    if Code.ensure_compiled(adapter) != {:module, adapter} do
      raise ArgumentError,
            "adapter #{inspect(adapter)} was not compiled, " <>
              "ensure it is correct and it is included as a project dependency"
    end

    behaviours =
      for {:behaviour, behaviours} <- adapter.__info__(:attributes),
          behaviour <- behaviours,
          do: behaviour

    unless RailwayIpc.Adapters.Impl in behaviours do
      raise ArgumentError,
            "expected :adapter option given to `use RailwayIpc.Broker` to list RailwayIpc.Adapters.Impl as a behaviour"
    end

    {otp_app, adapter, behaviours}
  end

  @doc """
  Retrieves the runtime configuration.
  """
  def runtime_config(broker, otp_app, adapter, opts) do
    config =
      Application.get_env(otp_app, broker, [])
      |> Keyword.merge(opts)
      |> Keyword.put(:otp_app, otp_app)

    case broker_init(broker, config) do
      {:ok, config} ->
        validate_config_over_adapter!(config, adapter)
        {:ok, config}

      {:error, error} ->
        {:error, error}

      unexpected ->
        {:error, unexpected}
    end
  end

  defp broker_init(broker, config) do
    if Code.ensure_loaded?(broker) and function_exported?(broker, :init, 1) do
      broker.init(config)
    else
      {:ok, config}
    end
  end

  defp validate_config_over_adapter!(config, adapter) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, :validate_config!, 1) do
      adapter.validate_config!(config)
    end
  end

  ## Callbacks

  def init({_name, broker, otp_app, adapter, opts}) do
    {:ok, opts} = runtime_config(broker, otp_app, adapter, opts)
    children = adapter.child_spec(opts)
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 0)
  end
end
