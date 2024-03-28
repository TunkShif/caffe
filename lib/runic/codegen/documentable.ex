defprotocol Runic.Codegen.Documentable do
  alias Runic.AST
  alias Runic.Codegen.Document

  @doc """
  Build codegen document struct from Runic AST.
  """
  @spec to_document(AST.t()) :: Document.t()
  def to_document(ast)
end
