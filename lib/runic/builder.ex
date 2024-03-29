# defmodule Runic.Builder do
#   @moduledoc """
#   DSL for defining Runic code.
#   """
#
#   alias Runic.Compiler
#   alias Runic.AST.Function
#
#   defmacro __using__(_) do
#     quote do
#       @runic_module true
#       Module.register_attribute(__MODULE__, :runic_function, accumulate: true)
#       @before_compile Runic.Builder
#
#       import Runic.Builder, only: [defun: 2, defun: 3]
#     end
#   end
#
#   defmacro defun(fun, opts \\ [], do: body) do
#     function = build_function(fun, body, opts)
#
#     quote do
#       @runic_function unquote(Macro.escape(function))
#       def unquote(fun), do: :erlang.nif_error("Function not available in current environment")
#     end
#   end
#
#   defmacro __before_compile__(env) do
#     functions =
#       env.module
#       |> Module.get_attribute(:runic_function)
#
#     quote do
#       def __runic_functions__ do
#         unquote(Macro.escape(functions))
#       end
#     end
#   end
#
#   defp build_function(fun, body, opts) do
#     dbg(body)
#     {name, _meta, params} = fun
#     params = if params, do: Enum.map(params, &Compiler.compile/1), else: []
#     body = Compiler.transform(body)
#     Function.new(name, params, body, opts)
#   end
# end
