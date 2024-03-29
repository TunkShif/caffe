defmodule Runic.Compiler do
  alias Runic.AST

  @type meta :: [
          # track the operator of the parent node
          parent: atom(),
          # track the side of a binary expression
          side: :left | :right | nil
        ]

  @doc """
  Transforms Elixir AST into Runic AST.
  """
  @spec transform(Macro.t()) :: AST.t()
  def transform(ast), do: compile(ast)

  @doc """
  Emits JavaScript code from Runic AST.
  """
  @spec emit(AST.t()) :: String.t()
  def emit(ast, width \\ 80) do
    AST.to_doc(ast)
    |> Inspect.Algebra.format(width)
    |> IO.iodata_to_binary()
  end

  def codegen(ast) do
    transform(ast)
    |> IO.inspect()
    |> emit()
    |> IO.puts()
  end

  # Literals that return themselves when quoted, including:
  # atoms, numbers, lists, strings, and tuples with two elements
  defguardp is_primitive(term) when is_atom(term) or is_number(term) or is_binary(term)
  defguardp is_literal(term) when is_primitive(term) or is_list(term)

  defp compile(ast), do: compile(ast, parent: nil)

  defp compile(ast, _opts) when is_literal(ast), do: compile_literal(ast)
  defp compile({fst, snd}, _opts), do: compile_literal([fst, snd])

  # Variables which have AST structure like: `{identifier, meta, context}`
  defp compile({name, _meta, context}, _opts) when is_atom(name) and is_atom(context),
    do: compile_variable(name)

  # Calls which have AST structure like: {fun, meta, args}

  # Tuple and map literals
  @constructors [:{}, :%{}, :<<>>]
  defp compile({constructor, _meta, args}, _opts) when constructor in @constructors,
    do: compile_literal(constructor, args)

  # Block of code
  defp compile({:__block__, _meta, body}, _opts), do: compile_block(body)

  # Unary operators
  @unary_operators [:+, :-, :!, :not]
  defp compile({operator, _meta, [arg]}, _opts) when operator in @unary_operators,
    do: compile_unary(operator, arg)

  # Binary operators
  @binary_operators [
    :**,
    :*,
    :/,
    :+,
    :-,
    :<,
    :>,
    :<=,
    :>=,
    :==,
    :!=,
    :===,
    :!==,
    :&&,
    :and,
    :||,
    :or
  ]
  defp compile({operator, _meta, [_fst, _snd] = args}, opts) when operator in @binary_operators,
    do: compile_binary(operator, args, opts)

  # Dot access call
  defp compile({:., _meta, args}, _opts), do: compile_access(args)

  # All other calls 
  defp compile({name, meta, args}, _opts), do: compile_call(name, args, meta)

  defp compile_literal(term) when is_primitive(term),
    do: AST.Literal.new(term)

  defp compile_literal(term) when is_list(term),
    do: AST.Literal.new(:array, Enum.map(term, &compile/1))

  defp compile_literal(:{}, args),
    do: AST.Literal.new(:array, Enum.map(args, &compile/1))

  defp compile_literal(:%{}, args),
    do: AST.Literal.new(:object, Enum.map(args, fn {k, v} -> {compile(k), compile(v)} end))

  defp compile_variable(name), do: AST.Identifier.new(:var, name)

  defp compile_block(body), do: compile_block(body, [])

  defp compile_block([], _acc), do: AST.Block.new([])
  defp compile_block([last], acc), do: AST.Block.new(Enum.reverse(acc), compile(last))
  defp compile_block([node | rest], acc), do: compile_block(rest, [compile(node) | acc])

  # JavaScript operator precedences
  # Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Operator_precedence#table
  @call_prec {:left, 17}
  @prefix_prec {:unary, 14}
  @exp_prec {:right, 13}
  @factor_prec {:left, 12}
  @term_prec {:left, 11}
  @comparison_prec {:left, 9}
  @equality_prec {:left, 8}
  @and_prec {:left, 4}
  @or_prec {:left, 3}

  @precedences %{
    # prefix includes unary +, -, and !
    :prefix => @prefix_prec,
    :. => @call_prec,
    :** => @exp_prec,
    :* => @factor_prec,
    :/ => @factor_prec,
    :+ => @term_prec,
    :- => @term_prec,
    :< => @comparison_prec,
    :> => @comparison_prec,
    :<= => @comparison_prec,
    :>= => @comparison_prec,
    :== => @equality_prec,
    :!= => @equality_prec,
    :=== => @equality_prec,
    :!== => @equality_prec,
    :&& => @and_prec,
    :|| => @or_prec
  }

  defp compile_unary(:not, arg), do: compile_unary(:!, arg)

  defp compile_unary(operator, arg),
    do: AST.Unary.new(operator, compile(arg, :prefix))

  defp compile_binary(:and, args, opts), do: compile_binary(:&&, args, opts)
  defp compile_binary(:or, args, opts), do: compile_binary(:||, args, opts)

  defp compile_binary(operator, [fst, snd], opts) do
    parent = opts[:parent]
    side = opts[:side]

    node =
      AST.Binary.new(
        operator,
        compile(fst, parent: operator, side: :left),
        compile(snd, parent: operator, side: :right)
      )

    # check wether we should wrap the node in a group
    if parent do
      {_, prec_o} = get_precedence(operator)
      {assoc_p, prec_p} = get_precedence(parent)

      lower_prec? = prec_o < prec_p
      same_prec? = prec_o == prec_p
      same_assoc? = assoc_p == side
      wrap_node? = lower_prec? || (same_prec? && !same_assoc?)

      if wrap_node?, do: AST.Group.new(node), else: node
    else
      node
    end
  end

  # Annoymous function call
  defp compile_access([name]), do: compile(name)

  # Access an erlang module function like `:mod.fun`
  defp compile_access([mod, fun]) when is_atom(mod) and is_atom(fun),
    do: AST.Identifier.new(:fun, {mod, fun})

  # Access an elixir module function like `Mod.fun`
  defp compile_access([{:__aliases__, meta, parts}, fun]),
    do: AST.Identifier.new(:fun, {meta[:alias] || Module.concat(parts), fun})

  # Field access like `foo.bar`
  defp compile_access([root, key]), do: AST.Access.new(compile(root), key)

  # Non-qualified function call like `fun()`
  defp compile_call(name, args, meta) when is_atom(name),
    do: AST.Call.new(AST.Identifier.new(:var, name), Enum.map(args, &compile/1), meta)

  # All other calls
  defp compile_call(name, args, meta),
    do: AST.Call.new(compile(name), Enum.map(args, &compile/1), meta)

  defp precedences, do: @precedences
  defp get_precedence(op), do: Map.get(precedences(), op, {:unary, 0})
end
