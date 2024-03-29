defprotocol Runic.AST do
  @type t :: Literal.t() | Variable.t() | Block.t()

  @doc """
  Build algebra documents from Runic AST.
  """
  @spec to_doc(t()) :: Inspect.Algebra.t()
  def to_doc(ast)
end

defmodule Runic.AST.Literal do
  @type t :: %__MODULE__{type: type(), value: value()}
  @type type :: :number | :string | :boolean | :null | :array | :object
  @type value :: number() | String.t() | boolean() | nil | list()

  defstruct [:type, :value]

  def new(type, value), do: %__MODULE__{type: type, value: value}

  def new(term) when is_nil(term), do: new(:null, nil)
  def new(term) when is_boolean(term), do: new(:boolean, term)
  def new(term) when is_number(term), do: new(:number, term)
  def new(term) when is_atom(term) or is_binary(term), do: new(:string, to_string(term))

  # Escapes quotes (double and single), double backslashes and others.
  # Adapted from Phoenix.HTML.javascript_escape/1
  # See: https://github.com/phoenixframework/phoenix_html/blob/v4.1.1/lib/phoenix_html.ex#L309
  def escape_string(data) when is_binary(data),
    do: escape_string(data, "")

  defp escape_string(<<0x2028::utf8, t::binary>>, acc),
    do: escape_string(t, <<acc::binary, "\\u2028">>)

  defp escape_string(<<0x2029::utf8, t::binary>>, acc),
    do: escape_string(t, <<acc::binary, "\\u2029">>)

  defp escape_string(<<0::utf8, t::binary>>, acc),
    do: escape_string(t, <<acc::binary, "\\u0000">>)

  defp escape_string(<<"</", t::binary>>, acc),
    do: escape_string(t, <<acc::binary, ?<, ?\\, ?/>>)

  defp escape_string(<<"\r\n", t::binary>>, acc),
    do: escape_string(t, <<acc::binary, ?\\, ?n>>)

  defp escape_string(<<h, t::binary>>, acc) when h in [?", ?', ?\\, ?`],
    do: escape_string(t, <<acc::binary, ?\\, h>>)

  defp escape_string(<<h, t::binary>>, acc) when h in [?\r, ?\n],
    do: escape_string(t, <<acc::binary, ?\\, ?n>>)

  defp escape_string(<<h, t::binary>>, acc),
    do: escape_string(t, <<acc::binary, h>>)

  defp escape_string(<<>>, acc), do: acc

  defimpl Runic.AST do
    import Inspect.Algebra

    def to_doc(%{type: :null}), do: "null"

    def to_doc(%{type: :string} = literal),
      do: "\"#{Runic.AST.Literal.escape_string(literal.value)}\""

    def to_doc(%{type: :array} = literal) do
      opts = %Inspect.Opts{limit: :infinity}
      fun = fn e, _opts -> Runic.AST.to_doc(e) end
      container_doc("[", literal.value, "]", opts, fun)
    end

    def to_doc(%{type: :object} = literal) do
      opts = %Inspect.Opts{limit: :infinity}
      fun = fn {key, value}, _opts -> concat([key, ": ", Runic.AST.to_doc(value)]) end
      container_doc("{", literal.value, "}", opts, fun)
    end

    def to_doc(literal), do: to_string(literal.value)
  end
end

defmodule Runic.AST.Variable do
  @type t :: %__MODULE__{name: String.t()}

  defstruct [:name]

  def new(name), do: %__MODULE__{name: name}

  defimpl Runic.AST do
    def to_doc(variable) do
      to_string(variable.name)
    end
  end
end

defmodule Runic.AST.Group do
  # The group node wraps an AST node inside a pair of parentheses.
  @type t :: %__MODULE__{node: Runic.AST.t()}

  defstruct [:node]

  def new(node), do: %__MODULE__{node: node}

  defimpl Runic.AST do
    import Inspect.Algebra

    def to_doc(group) do
      group(concat(["(", Runic.AST.to_doc(group.node), ")"]))
    end
  end
end

defmodule Runic.AST.Block do
  # The `body` field contains a list of AST nodes except the last one from the original Elixir AST node,
  # the last node from the original Elixir AST is stored in the `return` field.
  @type t :: %__MODULE__{body: [Runic.AST.t()], return: Runic.AST.t() | nil}

  defstruct [:body, :return]

  def new(body, return \\ nil), do: %__MODULE__{body: body, return: return}
end

defmodule Runic.AST.Unary do
  @type t :: %__MODULE__{operator: operator(), value: Runic.AST.t()}
  @type operator :: :+ | :- | :!

  defstruct [:operator, :value]

  def new(operator, value), do: %__MODULE__{operator: operator, value: value}

  defimpl Runic.AST do
    import Inspect.Algebra

    def to_doc(%{operator: operator} = unary) when operator in [:+, :-] do
      # Add a space after the unary operator if the value itself is also a unary expression to
      # prevent generating code like `--foo`, instead generating `- -foo` which is fine for js
      sep =
        case unary.value do
          %Runic.AST.Unary{} -> " "
          _ -> empty()
        end

      group(
        concat([
          to_string(unary.operator),
          sep,
          Runic.AST.to_doc(unary.value)
        ])
      )
    end

    def to_doc(unary) do
      group(
        concat([
          to_string(unary.operator),
          Runic.AST.to_doc(unary.value)
        ])
      )
    end
  end
end

defmodule Runic.AST.Binary do
  @type t :: %__MODULE__{
          operator: operator(),
          left: Runic.AST.t(),
          right: Runic.AST.t()
        }
  @type operator ::
          :** | :* | :/ | :+ | :- | :< | :> | :<= | :>= | :== | :!= | :=== | :!== | :&& | :||

  defstruct [:operator, :left, :right]

  def new(operator, left, right), do: %__MODULE__{operator: operator, left: left, right: right}

  defimpl Runic.AST do
    import Inspect.Algebra

    def to_doc(binary) do
      group(
        concat([
          Runic.AST.to_doc(binary.left),
          " #{binary.operator} ",
          Runic.AST.to_doc(binary.right)
        ])
      )
    end
  end
end
