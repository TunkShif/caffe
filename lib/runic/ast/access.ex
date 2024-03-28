defmodule Runic.AST.Access do
  alias Runic.Codegen.Documentable

  defstruct [:left, :right, :type]

  def new(left, right) do
    %__MODULE__{left: left, right: right, type: :dot}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(access) do
      [
        Documentable.to_document(access.left),
        text("."),
        Documentable.to_document(access.right)
      ]
    end
  end
end
