defmodule Runic.Compiler.Expression do
  alias Runic.Compiler.Literal
  alias Runic.AST.{Unary, Binary, Block, Identifier, Access, Call}

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

  def compile({atom, _meta, context}) when is_atom(atom) and is_atom(context) do
    Identifier.new(atom)
  end

  # dot syntax like `foo.bar` is always wrapped in a function call
  def compile({ast, [no_parens: true], []}), do: compile(ast)

  def compile({:., _meta, [left, right]}) when is_atom(right) do
    Access.new(compile(left), Identifier.new(right))
  end

  @constructors [:{}, :%{}]

  # local function calls like `foo()`
  def compile({name, _meta, args})
      when is_atom(name) and is_list(args) and name not in @constructors do
    args = Enum.map(args, &compile/1)
    Call.new(name, args)
  end

  def compile(ast), do: Literal.compile(ast)
end
