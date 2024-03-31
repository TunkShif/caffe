defmodule Runic.IEx do
  @doc """
  Debug the codegen process for the given quoted expression.
  """
  defmacro runic(do: block) do
    IO.puts(~s(#Quoted<\n#{inspect(block)}\n>))

    ast = Runic.Compiler.transform(block, __CALLER__)

    IO.inspect(ast)

    code = Runic.Compiler.codegen(ast)

    IO.puts(~s(#Codegen<\n#{code}\n>))

    :ok
  end
end
