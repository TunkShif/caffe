defmodule Runic.Builder do
  @moduledoc """
  DSL for defining Runic code.
  """

  # @type options :: [async: boolean()]
  #
  # defmacro defun(head, opts \\ [], do: body) do
  #   IO.puts("???")
  #   IO.inspect(__CALLER__)
  #   # IO.inspect(body)
  #   #
  #   # Macro.prewalk(body, fn ast -> Macro.expand(ast, __CALLER__) end)
  #   # |> IO.inspect()
  #
  #   quote do
  #     @runic_function unquote(Macro.escape({head, body, opts}))
  #     def unquote(head) do
  #       raise "Runic module function cannot be called in BEAM runtime."
  #       unquote(body)
  #     end
  #   end
  # end
  #
  # defmacro __before_compile__(_env) do
  #   quote do
  #     def __runic_env__, do: __ENV__
  #
  #     def __runic_functions__, do: @runic_function
  #   end
  # end
end
