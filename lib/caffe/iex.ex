defmodule Caffe.IEx do
  @doc """
  Debug the codegen process for the given quoted expression.
  """
  defmacro caffe(do: block) do
    IO.puts(~s(#Quoted<\n#{inspect(block)}\n>))

    ast = Caffe.Compiler.transform(block, __CALLER__)

    IO.inspect(ast)

    code = Caffe.Compiler.codegen(ast)

    IO.puts(~s(#Codegen<\n#{code}\n>))

    :ok
  end
end
