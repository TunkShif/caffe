defmodule Runic.AST.Identifier do
  alias Runic.Codegen.Documentable

  defstruct [:name]

  def new(name) do
    %__MODULE__{name: to_string(name)}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(identifier) do
      text(identifier.name)
    end
  end
end
