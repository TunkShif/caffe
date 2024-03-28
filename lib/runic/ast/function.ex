defmodule Runic.AST.Function do
  alias Runic.Codegen.Documentable

  defstruct [:name, :params, :body, :async, :exported]

  def new(name, params, body, opts \\ []) do
    %__MODULE__{name: to_string(name), params: params, body: body, async: opts[:async] || false}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(function) do
      [
        text("function #{function.name}("),
        Enum.map(function.params, &[Documentable.to_document(&1), text(", ")]),
        text(") {"),
        nest([
          break(),
          Documentable.to_document(function.body)
        ]),
        break(),
        text("}")
      ]
    end
  end
end
