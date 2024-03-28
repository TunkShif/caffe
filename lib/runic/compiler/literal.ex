defmodule Runic.Compiler.Literal do
  alias Runic.Compiler.Expression
  alias Runic.AST.{Primitive, Array, Object}

  defguardp is_primitive(ast)
            when is_number(ast) or is_boolean(ast) or is_atom(ast) or is_binary(ast)

  def compile(ast) when is_primitive(ast) do
    Primitive.new(ast)
  end

  def compile(ast) when is_list(ast) do
    Enum.map(ast, &Expression.compile/1)
    |> Array.new()
  end

  def compile({hd, tl}) do
    Array.new([Expression.compile(hd), Expression.compile(tl)])
  end

  def compile({:{}, _meta, children}) do
    Enum.map(children, &Expression.compile/1)
    |> Array.new()
  end

  def compile({:%{}, _meta, children}) do
    Enum.map(children, fn {key, value} -> {compile(key), Expression.compile(value)} end)
    |> Object.new()
  end
end
