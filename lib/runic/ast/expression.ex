defmodule Runic.AST.Expression do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  defmodule Unary do
    @type t :: %__MODULE__{
            op: String.t(),
            right: AST.t()
          }

    defstruct [:op, :right]

    def new(op, right) do
      %Unary{op: map_operator(op) |> to_string(), right: right}
    end

    defp map_operator(:not), do: :!
    defp map_operator(op), do: op

    defimpl Documentable do
      import Runic.Codegen.Document

      def to_document(unary) do
        [
          text(unary.op),
          Documentable.to_document(unary.right)
        ]
      end
    end
  end

  defmodule Binary do
    @type t :: %__MODULE__{
            op: String.t(),
            left: AST.t(),
            right: AST.t()
          }

    defstruct [:op, :left, :right]

    def new(op, left, right) do
      %Binary{op: map_operator(op) |> to_string(), left: left, right: right}
    end

    defp map_operator(:==), do: :===
    defp map_operator(:!=), do: :!==
    defp map_operator(:and), do: :&&
    defp map_operator(:or), do: :||
    defp map_operator(op), do: op

    defimpl Documentable do
      import Runic.Codegen.Document

      # TODO: handle binary operator precedence
      def to_document(binary) do
        [
          text("("),
          Documentable.to_document(binary.left),
          text(" #{binary.op} "),
          Documentable.to_document(binary.right),
          text(")")
        ]
      end
    end
  end

  defmodule Ternary do
    @type t :: %__MODULE__{
            condition: AST.t(),
            left: AST.t(),
            right: AST.t()
          }

    defstruct [:condition, :left, :right]

    def new(condition, left, right) do
      %Ternary{condition: condition, left: left, right: right}
    end
  end

  defmodule Block do
    @type t :: %__MODULE__{
            body: [AST.t()],
            return: AST.t() | nil
          }

    defstruct [:body, :return]

    def new(body) do
      %Block{body: body}
    end

    defimpl Documentable do
      def to_document(block) do
        Enum.map(block.children, &Documentable.to_document/1)
      end
    end
  end
end
