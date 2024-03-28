defmodule Runic.AST.Object do
  alias Runic.Codegen.Documentable

  defstruct [:children]

  def new(children) do
    %__MODULE__{children: children}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(object) do
      case object.children do
        [] ->
          text("{}")

        children ->
          [
            text("{"),
            nest(
              list(
                for {key, value} <- children,
                    do: [
                      Documentable.to_document(key),
                      text(": "),
                      Documentable.to_document(value)
                    ]
              )
            ),
            break(),
            text("}")
          ]
      end
    end
  end
end
