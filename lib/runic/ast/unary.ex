defmodule Runic.AST.Unary do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          op: String.t(),
          right: AST.t()
        }

  defstruct [:op, :right]

  def new(op, right) do
    %__MODULE__{op: map_operator(op) |> to_string(), right: right}
  end

  defp map_operator(:not), do: :!
  defp map_operator(op), do: op

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(unary) do
      [
        text(unary.op),
        Documentable.to_document(unary.right)
      ]
    end
  end
end
