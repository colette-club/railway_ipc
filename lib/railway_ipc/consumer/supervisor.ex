defmodule RailwayIpc.Consumer.Supervisor do
  @moduledoc false

  @doc """
  Starts the broker supervisor.
  """
  def start_link(consumer, otp_app, adapter, use_opts, opts) do
    sup_opts =
      if name = Keyword.get(opts, :name, consumer),
        do: [name: String.to_atom("#{name}.Supervisor")],
        else: []

    Supervisor.start_link(
      __MODULE__,
      {name, consumer, otp_app, adapter, use_opts, opts},
      sup_opts
    )
  end

  @doc """
  Retrieves the compile time configuration.
  """
  def compile_time_config(opts) do
    broker = opts[:broker]

    unless broker do
      raise ArgumentError, "missing :broker option on use RailwayIpc.Consumer"
    end

    if Code.ensure_compiled(broker) != {:module, broker} do
      raise ArgumentError,
            "broker #{inspect(broker)} was not compiled, " <>
              "ensure it is correct and it is included as a project dependency"
    end

    otp_app = broker.__otp_app__()
    adapter = broker.__adapter__().consumer_adapter()

    if Code.ensure_compiled(adapter) != {:module, adapter} do
      raise ArgumentError,
            "adapter #{inspect(adapter)} was not compiled, " <>
              "ensure it is correct and it is included as a project dependency"
    end

    if Code.ensure_loaded?(adapter) and function_exported?(adapter, :validate_config!, 1) do
      adapter.validate_config!(opts)
    end

    {otp_app, adapter}
  end

  def init({name, consumer, otp_app, adapter, use_opts, opts}) do
    opts =
      Keyword.merge(use_opts, opts)
      |> Keyword.put_new(:name, name)
      |> Keyword.put_new(:module, consumer)
      |> Keyword.put_new(:otp_app, otp_app)

    children = adapter.child_spec(opts)
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 0)
  end
end
