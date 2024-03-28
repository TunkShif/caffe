defmodule Runic.Builder do
  @moduledoc """
  DSL for defining Runic code.
  """

  defmacro __using__(_) do
    quote do
      @__runic_module__ true
    end
  end
end
