defmodule RailwayIpc.TestHelpers do
  @spec deserialize(binary) :: term
  def deserialize(str) when is_binary(str) do
    str
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end

  @spec serialize(term) :: binary
  def serialize(term) do
    term
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end
end
