defmodule Runic.AST.Binary do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          op: String.t(),
          left: AST.t(),
          right: AST.t()
        }

  defstruct [:op, :left, :right]

  def new(op, left, right) do
    %__MODULE__{op: map_operator(op) |> to_string(), left: left, right: right}
  end

  defp map_operator(:==), do: :===
  defp map_operator(:!=), do: :!==
  defp map_operator(:and), do: :&&
  defp map_operator(:or), do: :||
  defp map_operator(op), do: op

  defimpl Documentable do
    import Runic.Codegen.Document

    # TODO: handle binary operator precedence
    def to_document(binary) do
      [
        text("("),
        Documentable.to_document(binary.left),
        text(" #{binary.op} "),
        Documentable.to_document(binary.right),
        text(")")
      ]
    end
  end
end
