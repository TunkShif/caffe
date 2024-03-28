defmodule Runic.AST.Block do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          body: [AST.t()],
          return: AST.t() | nil
        }

  defstruct [:body, :return]

  def new(body) do
    %__MODULE__{body: body}
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(block) do
      case block.body do
        [] ->
          empty()

        [hd | tl] ->
          [
            [Documentable.to_document(hd), text(";")]
            | Enum.map(tl, &[break(), Documentable.to_document(&1), text(";")])
          ]
      end
    end
  end
end
