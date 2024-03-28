defmodule Runic.AST.Call do
  alias Runic.Codegen.Documentable

  defstruct [:name, :args, :mod]

  def new(name, args, opts \\ []) do
    mod = opts[:mod]
    %__MODULE__{name: to_string(name), args: args, mod: mod}
  end

  def local?(%__MODULE__{mod: nil}), do: true
  def local?(%__MODULE__{}), do: false

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(call) do
      # TODO: do not break args
      args =
        case call.args do
          [] ->
            text("()")

          args ->
            [
              text("("),
              nest(list(Enum.map(args, &Documentable.to_document/1))),
              break(),
              text(")")
            ]
        end

      [text(call.name), args]
    end
  end
end
