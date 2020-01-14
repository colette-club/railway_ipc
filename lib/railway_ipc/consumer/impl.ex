defmodule RailwayIpc.Consumer.Impl do
  @moduledoc false

  @callback child_spec(config :: Keyword.t()) ::
              [:supervisor.child_spec() | {module(), term()} | module()]

  @callback validate_config!(config :: Keyword.t()) :: :ok

  @optional_callbacks validate_config!: 1
end
