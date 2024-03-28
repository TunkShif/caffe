defmodule Runic.Codegen.Document do
  @type t() :: nil | :break | {:text, String.t()} | [t()]

  @doc """
  Build an empty text.
  """
  @spec empty :: t()
  def empty, do: nil

  @doc """
  Build a newline.
  """
  @spec break :: t()
  def break, do: :break

  @doc """
  Build a text segment.
  """
  @spec text(String.t()) :: t()
  def text(string), do: {:text, string}

  @doc """
  Build a nested document.
  """
  @spec nest(t()) :: t()
  def nest(:break), do: [:break, ident()]
  def nest(docs) when is_list(docs), do: Enum.map(docs, &nest/1)
  def nest(doc), do: doc

  @doc """
  Build a comma seperated list of documents with each element on its own line and a trailing comma.
  """
  @spec list(t()) :: t()
  def list(docs) do
    for doc <- docs, do: [break(), doc, text(",")]
  end

  @spec ident :: t()
  defp ident, do: text("  ")
end
