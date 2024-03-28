defmodule Runic.AST.Function do
  defstruct [:name, :params, :body, :async]

  def new(name, params, body, opts \\ []) do
    %__MODULE__{name: name, params: params, body: body, async: opts[:async] || false}
  end
end
