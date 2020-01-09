defmodule RailwayIpc.Utils do
  def module_defined?(module) do
    try do
      # forces module to be loaded
      module.__info__(:module)
      true
    rescue
      UndefinedFunctionError -> false
    end
  end

  def module_has_function?(module, function) when is_atom(function) do
    module_has_functions?(module, [function])
  end

  def module_has_functions?(module, functions) when is_list(functions) do
    module_functions = module.__info__(:functions)

    Enum.all?(functions, fn function ->
      Keyword.has_key?(module_functions, function)
    end)
  end
end
