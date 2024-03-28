defmodule Runic.Compiler do
  alias Runic.AST

  @doc """
  Compiles Runic AST to JavaScript code.
  """
  @spec compile(AST.t()) :: String.t()
  def compile(ast) do
    Runic.Codegen.Documentable.to_document(ast)
    |> Runic.Codegen.build()
  end

  @doc """
  Transforms Elixir AST into Runic AST.
  """
  @spec transform(Macro.t()) :: AST.t()
  def transform(ast) do
    Runic.Compiler.Expression.compile(ast)
  end
end
