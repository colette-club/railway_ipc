defmodule RailwayIpc.Utils do
  @moduledoc false

  @doc """
  Returns true if module is defined, false otherwise
  """
  @spec module_defined?(module :: module()) :: true | false
  def module_defined?(module) do
    try do
      # forces module to be loaded
      module.__info__(:module)
      true
    rescue
      UndefinedFunctionError -> false
    end
  end

  @doc """
  Returns true if module defines function, false otherwise
  """
  @spec module_defines_function?(module :: module(), function :: atom()) :: true | false
  def module_defines_function?(module, function) when is_atom(function) do
    module_defines_functions?(module, [function])
  end

  @doc """
  Returns true if module defines all functions, false otherwise
  """
  @spec module_defines_functions?(module :: module(), functions :: [atom()]) :: true | false
  def module_defines_functions?(module, functions) when is_list(functions) do
    module_functions = module.__info__(:functions)

    Enum.all?(functions, fn function ->
      Keyword.has_key?(module_functions, function)
    end)
  end
end
