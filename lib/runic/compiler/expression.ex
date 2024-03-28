defmodule Runic.Compiler.Expression do
  alias Runic.Compiler.Literal
  alias Runic.AST.Expression.{Unary, Binary, Block}

  @unary_ops [:+, :-, :!, :not]
  @binary_ops [:+, :-, :*, :/, :>, :<, :>=, :<=, :==, :!=, :&&, :**, :<>, :||, :and, :or]

  def compile({op, _meta, [left, right]}) when op in @binary_ops do
    Binary.new(op, compile(left), compile(right))
  end

  def compile({op, _meta, [right]}) when op in @unary_ops do
    Unary.new(op, compile(right))
  end

  def compile({:__block__, _meta, children}) do
    Enum.map(children, &compile/1)
    |> Block.new()
  end

  def compile(ast), do: Literal.compile(ast)
end
