defmodule RailwayIpc.Adapters.Impl do
  @moduledoc """
  Specifies the minimal API required for adapters.
  """

  @type t :: module

  @doc """
  Returns the child specs of the adapter
  """
  @callback child_spec(config :: Keyword.t()) ::
              [:supervisor.child_spec() | {module(), term()} | module()]

  @doc """
  Validates the provided configuration
  """
  @callback validate_config!(config :: Keyword.t()) :: :ok

  @doc """
  Returns the Consumer module for the adapter
  """
  @callback consumer_adapter() :: module()

  @doc """
  Publishes a payload with the given metadata
  """
  @callback publish(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
              :ok | {:error, error :: binary()}

  @doc """
  Publishes a payload with the given metadata and wait for the reply
  """
  @callback publish_sync(payload :: binary(), metadata :: map(), opts :: Keyword.t()) ::
              {:ok, response :: any()} | {:error, error :: binary()}

  @optional_callbacks validate_config!: 1
end
