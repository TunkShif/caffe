defmodule Runic.Codegen do
  alias Runic.Codegen.Document

  @doc """
  Build document to string.
  """
  @spec build(Document.t()) :: String.t()
  def build(doc) do
    to_iodata(doc) |> IO.iodata_to_binary()
  end

  defp to_iodata(doc), do: to_iodata(doc, [])
  defp to_iodata(nil, acc), do: acc
  defp to_iodata(:break, acc), do: ["\n" | acc]
  defp to_iodata({:text, string}, acc), do: [string | acc]
  defp to_iodata(docs, acc) when is_list(docs), do: [Enum.map(docs, &to_iodata/1) | acc]
end
