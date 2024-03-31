defprotocol Caffe.AST do
  @type t ::
          Caffe.AST.Literal.t()
          | Caffe.AST.Identifier.t()
          | Caffe.AST.Group.t()
          | Caffe.AST.Block.t()
          | Caffe.AST.Unary.t()
          | Caffe.AST.Binary.t()
          | Caffe.AST.Access.t()
          | Caffe.AST.Call.t()
          | Caffe.AST.Function.t()

  @doc """
  Build algebra documents from Caffe AST.
  """
  @spec to_doc(t()) :: Inspect.Algebra.t()
  def to_doc(ast)
end

defmodule Caffe.AST.Literal do
  @type t ::
          %__MODULE__{type: :number, value: number()}
          | %__MODULE__{type: :string, value: String.t()}
          | %__MODULE__{type: :null, value: nil}
          | %__MODULE__{type: :array, value: [Caffe.AST.t()]}
          | %__MODULE__{type: :object, value: [{Caffe.AST.t(), Caffe.AST.t()}]}

  @derive [Caffe.Resolver]
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

  defimpl Caffe.AST do
    alias Caffe.AST.Literal

    import Inspect.Algebra

    def to_doc(%{type: :null}), do: "null"

    def to_doc(%{type: :string} = literal),
      do: "\"#{Caffe.AST.Literal.escape_string(literal.value)}\""

    def to_doc(%{type: :array} = literal) do
      opts = %Inspect.Opts{limit: :infinity}
      fun = fn e, _opts -> Caffe.AST.to_doc(e) end
      container_doc("[", literal.value, "]", opts, fun)
    end

    def to_doc(%{type: :object} = literal) do
      opts = %Inspect.Opts{limit: :infinity}

      fun = fn
        {%Literal{type: :string} = key, value}, _opts ->
          group(
            concat([
              Caffe.AST.to_doc(key),
              ": ",
              Caffe.AST.to_doc(value)
            ])
          )

        {key, value}, _opts ->
          group(
            concat([
              "[",
              Caffe.AST.to_doc(key),
              "]: ",
              Caffe.AST.to_doc(value)
            ])
          )
      end

      container_doc("{", literal.value, "}", opts, fun)
    end

    def to_doc(literal), do: to_string(literal.value)
  end
end

defmodule Caffe.AST.Identifier do
  # An identifier node represents a variable (like `foo`) or a module name (like `:mod` or `Mod`).
  @type t ::
          %__MODULE__{type: :var, value: atom(), counter: integer() | nil}
          | %__MODULE__{type: :mod, value: atom(), counter: nil}

  defstruct [:type, :value, :counter]

  def new(type, value, counter \\ nil),
    do: %__MODULE__{type: type, value: value, counter: counter}

  defimpl Caffe.AST do
    def to_doc(%{type: :var} = identifier) do
      to_string(identifier.value)
    end

    def to_doc(%{type: :mod} = identifier) do
      # TODO: format module name and only Elixir module can be used
      inspect(identifier.value) |> String.replace(".", "$")
    end
  end
end

defmodule Caffe.AST.Group do
  # The group node wraps an AST node inside a pair of parentheses.
  @type t :: %__MODULE__{node: Caffe.AST.t()}

  defstruct [:node]

  def new(node), do: %__MODULE__{node: node}

  defimpl Caffe.AST do
    import Inspect.Algebra

    def to_doc(group) do
      group(concat(["(", Caffe.AST.to_doc(group.node), ")"]))
    end
  end
end

defmodule Caffe.AST.Block do
  # The `body` field contains a list of AST nodes except the last one from the original Elixir AST node,
  # the last node from the original Elixir AST is stored in the `return` field.
  @type t :: %__MODULE__{body: [Caffe.AST.t()], return: Caffe.AST.t() | nil}

  defstruct [:body, :return]

  def new(body, return \\ nil), do: %__MODULE__{body: body, return: return}
end

defmodule Caffe.AST.Unary do
  @type t :: %__MODULE__{operator: operator(), value: Caffe.AST.t()}
  @type operator :: :+ | :- | :!

  defstruct [:operator, :value]

  def new(operator, value), do: %__MODULE__{operator: operator, value: value}

  defimpl Caffe.AST do
    import Inspect.Algebra

    def to_doc(%{operator: operator} = unary) when operator in [:+, :-] do
      # Add a space after the unary operator if the value itself is also a unary expression to
      # prevent generating code like `--foo`, instead generating `- -foo` which is fine for js
      sep =
        case unary.value do
          %Caffe.AST.Unary{} -> " "
          _ -> empty()
        end

      group(
        concat([
          to_string(unary.operator),
          sep,
          Caffe.AST.to_doc(unary.value)
        ])
      )
    end

    def to_doc(unary) do
      group(
        concat([
          to_string(unary.operator),
          Caffe.AST.to_doc(unary.value)
        ])
      )
    end
  end
end

defmodule Caffe.AST.Binary do
  @type t :: %__MODULE__{
          operator: operator(),
          left: Caffe.AST.t(),
          right: Caffe.AST.t()
        }
  @type operator ::
          :** | :* | :/ | :+ | :- | :< | :> | :<= | :>= | :== | :!= | :=== | :!== | :&& | :||

  defstruct [:operator, :left, :right]

  def new(operator, left, right), do: %__MODULE__{operator: operator, left: left, right: right}

  defimpl Caffe.AST do
    import Inspect.Algebra

    def to_doc(binary) do
      group(
        concat([
          Caffe.AST.to_doc(binary.left),
          " #{binary.operator} ",
          Caffe.AST.to_doc(binary.right)
        ])
      )
    end
  end
end

defmodule Caffe.AST.Access do
  @type t :: %__MODULE__{root: Caffe.AST.t(), key: Caffe.AST.t(), type: type()}
  @type type :: :dot | :brakcet

  defstruct [:root, :key, :type]

  def new(root, key, type \\ :dot), do: %__MODULE__{root: root, key: key, type: type}

  defimpl Caffe.AST do
    import Inspect.Algebra

    def to_doc(%{type: :dot} = access) do
      group(
        concat([
          Caffe.AST.to_doc(access.root),
          ".",
          Caffe.AST.to_doc(access.key)
        ])
      )
    end

    def to_doc(%{type: :bracket} = access) do
      group(
        concat([
          Caffe.AST.to_doc(access.root),
          "[",
          Caffe.AST.to_doc(access.key),
          "]"
        ])
      )
    end
  end
end

defmodule Caffe.AST.Call do
  @type t :: %__MODULE__{name: Caffe.AST.t(), args: [Caffe.AST.t()], no_parens: boolean()}

  defstruct [:name, :args, :no_parens]

  def new(name, args, opts \\ []),
    do: %__MODULE__{name: name, args: args, no_parens: Keyword.get(opts, :no_parens, false)}

  defimpl Caffe.AST do
    import Inspect.Algebra

    def to_doc(call) do
      opts = %Inspect.Opts{limit: :infinity}
      fun = fn e, _opts -> Caffe.AST.to_doc(e) end

      group(
        concat([
          Caffe.AST.to_doc(call.name),
          container_doc("(", call.args, ")", opts, fun)
        ])
      )
    end
  end
end

defmodule Caffe.AST.Function do
  @type t :: %__MODULE__{
          mod: Caffe.AST.Identifier.t(),
          name: atom(),
          arity: non_neg_integer(),
          params: [param()],
          guard: Caffe.AST.t() | nil,
          body: Caffe.AST.Block.t(),
          async: boolean(),
          receiver: boolean(),
          exported: boolean()
        }

  @type param :: atom() | {atom(), term()}

  defstruct [:mod, :name, :arity, :params, :guard, :body, :async, :receiver, :exported]
end
