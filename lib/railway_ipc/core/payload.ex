defmodule RailwayIpc.Core.Payload do
  @moduledoc false

  @behaviour RailwayIpc.PayloadBehaviour

  import RailwayIpc.Utils, only: [module_defined?: 1, module_has_function?: 2, module_has_functions?: 2]

  def decode(payload) when not is_binary(payload) do
    {:error, "Malformed JSON given: #{payload}. Must be a string"}
  end

  def decode(payload) do
    with {:decode_json, {:ok, %{"type" => type, "encoded_message" => encoded_message}}} <- {
           :decode_json,
           Jason.decode(payload)
         },
         {:convert_module, module} <- {:convert_module, module_from_type(type)},
         {:check_module_exists, true} <- {:check_module_exists, module_defined?(module)},
         {:check_module_functions, true} <- {:check_module_functions, module_has_function?(module, :decode)},
         {:decode_message, message} <- {:decode_message, decode_message(module, encoded_message)} do
      {:ok, message}
    else
      {:decode_json, {:ok, _}} ->
        {:error, "Missing keys in payload: #{payload}. Expecting type and encoded_message keys"}

      {:decode_json, {:error, _}} ->
        {:error, "Malformed JSON given: #{payload}"}

      {:check_module_exists, false} ->
        %{"type" => type} = Jason.decode!(payload)
        {:error, "Unknown message type #{type}"}

      {:check_module_functions, false} ->
        %{"type" => type} = Jason.decode!(payload)
        {:error, "Invalid message type #{type}"}
    end
  end

  def encode(protobuf_struct) do
    ensure_protobuf_struct!(protobuf_struct)

    {
      :ok,
      %{
        type: encode_type(protobuf_struct),
        encoded_message: encode_message(protobuf_struct)
      }
      |> Jason.encode!()
    }
  end

  defp ensure_protobuf_struct!(%_{} = protobuf_struct) do
    protobuf_struct.__struct__
    |> module_has_functions?([:encode, :decode, :new])
    |> case do
      true -> :ok
      false -> invalid_protobuf_struct!(protobuf_struct)
    end
  end
  defp ensure_protobuf_struct!(protobuf_struct), do: invalid_protobuf_struct!(protobuf_struct)

  defp invalid_protobuf_struct!(protobuf_struct) do
    raise ArgumentError, "An invalid payload has been provided: #{inspect protobuf_struct}. Please, provide a protobuf payload."
  end

  defp encode_message(%_{} = protobuf_struct) do
    protobuf_struct
    |> protobuf_struct.__struct__.encode
    |> Base.encode64()
  end

  defp encode_type(protobuf_struct) do
    module = protobuf_struct.__struct__

    module_name =
      module
      |> to_string

    Regex.replace(~r/\AElixir\./, module_name, "")
    |> String.replace(".", "::")
  end

  defp module_from_type(type) do
    type
    |> String.split("::")
    |> Module.concat()
  end

  defp decode_message(module, encoded_message) do
    encoded_message
    |> Base.decode64!(ignore: :whitespace)
    |> module.decode
  end
end
