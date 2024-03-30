defmodule Runic.Builder do
  @moduledoc """
  DSL for defining Runic code.
  """

  # defmacro defun(head, opts \\ [], do: body) do
  #   IO.puts("\n")
  #
  #   quote do
  #     @runic_function unquote(nil)
  #     def unquote(head) do
  #       :erlang.nif_error("function not available in current environment")
  #       unquote(body)
  #     end
  #   end
  # end
  #
  # defmacro __before_compile__(env) do
  #   functions = Module.get_attribute(env.module, :runic_function)
  #
  #   quote do
  #     def __runic_functions__ do
  #       unquote(Macro.escape(functions))
  #     end
  #   end
  # end
end
