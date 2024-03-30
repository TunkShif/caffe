defmodule Runic do
  @moduledoc """
  Documentation for `Runic`.
  """

  # defmacro __using__(_) do
  #   quote do
  #     @runic_module true
  #     Module.register_attribute(__MODULE__, :runic_function, accumulate: true)
  #     @before_compile Runic.Builder
  #
  #     import Runic.Builder, only: [defun: 2, defun: 3]
  #   end
  # end

  defmacro q(do: block) do
    IO.puts("+========= original elixir ast =========+")
    IO.inspect(block)
    IO.puts("+========= original elixir ast =========+\n")

    Runic.Compiler.codegen(block, __CALLER__)

    nil
  end
end
