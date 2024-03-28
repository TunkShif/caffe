defmodule Runic.AST.Array do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          children: AST.t()
        }
  defstruct [:children]

  def new(children) do
    %__MODULE__{children: children}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(array) do
      case array.children do
        [] ->
          text("[]")

        children ->
          [
            text("["),
            nest(list(Enum.map(children, &Documentable.to_document/1))),
            break(),
            text("]")
          ]
      end
    end
  end
end
