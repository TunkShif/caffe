defmodule Runic.AST.Ternary do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          condition: AST.t(),
          left: AST.t(),
          right: AST.t()
        }

  defstruct [:condition, :left, :right]

  def new(condition, left, right) do
    %__MODULE__{condition: condition, left: left, right: right}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(ternary) do
      [
        text("("),
        Documentable.to_document(ternary.condition),
        text(") ? "),
        text("("),
        Documentable.to_document(ternary.left),
        text(") : "),
        Documentable.to_document(ternary.right),
        text(")")
      ]
    end
  end
end
