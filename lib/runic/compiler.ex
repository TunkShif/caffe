defmodule Runic.Compiler do
  alias Runic.AST

  @type context :: %{
          env: Macro.Env.t(),
          # track the operator of the parent node
          parent: atom(),
          # track the current branch if parent is a binary expression
          branch: :left | :right | nil
        }

  def codegen(ast, env \\ nil) do
    context = %{
      env: env || __ENV__,
      parent: nil,
      branch: nil
    }

    o = compile(ast, context)

    IO.puts("+========= runic ast =========+")
    IO.inspect(o)
    IO.puts("+========= runic ast =========+\n")

    IO.puts("+========= codegen output =========+")

    AST.to_doc(o)
    |> Inspect.Algebra.format(100)
    |> IO.iodata_to_binary()
    |> IO.puts()

    IO.puts("+========= codegen output =========+\n")
  end

  @spec compile_quoted(Macro.t(), Macro.Env.t()) :: String.t()
  def compile_quoted(quoted, env) do
    context = %{
      env: env,
      parent: nil,
      branch: nil
    }

    compile(quoted, context)
    |> Runic.Resolver.resolve()
    |> AST.to_doc()
    |> Inspect.Algebra.format(100)
    |> IO.iodata_to_binary()
  end

  # Compiles literals that return themselves when quoted, including:
  # atoms, numbers, lists, strings, and tuples with two elements
  defguardp is_primitive(term) when is_atom(term) or is_number(term) or is_binary(term)
  defguardp is_literal(term) when is_primitive(term) or is_list(term)

  defp compile(ast, ctx) when is_literal(ast), do: compile_literal(ast, ctx)
  defp compile({fst, snd}, ctx), do: compile_literal([fst, snd], ctx)

  # Compiles variables which have AST like: `{identifier, meta, context}`
  defp compile({name, _meta, context}, ctx) when is_atom(name) and is_atom(context),
    do: compile_identifier(:var, name, ctx)

  # All the left code structures are just function calls,
  # which have AST like: `{fun, meta, args}`

  # Compiles tuple and map literals
  @constructors [:{}, :%{}, :<<>>]
  defp compile({constructor, _meta, args}, ctx) when constructor in @constructors,
    do: compile_literal(constructor, args, ctx)

  # Compiles aliased module name
  defp compile({:__aliases__, _meta, _args} = ast, ctx),
    do: compile_identifier(:mod, Macro.expand(ast, ctx.env), ctx)

  # Compiles code block
  defp compile({:__block__, _meta, body}, ctx), do: compile_block(body, ctx)

  # Compiles unary operators
  @unary_operators [:+, :-, :!, :not]
  defp compile({operator, _meta, [arg]}, ctx) when operator in @unary_operators,
    do: compile_unary(operator, arg, ctx)

  # Compiles binary operators
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
  defp compile({operator, _meta, [_fst, _snd] = args}, ctx) when operator in @binary_operators,
    do: compile_binary(operator, args, ctx)

  # Compiles dot access syntax
  defp compile({:., _meta, args}, ctx), do: compile_access(args, :dot, ctx)

  # Compiles bracket access syntax
  defp compile({{:., meta, [Access, :get]}, _meta, [root, key]} = ast, ctx) do
    if meta[:from_brackets] do
      compile_access([root, key], :bracket, ctx)
    else
      compile(ast, ctx)
    end
  end

  # Compiles all other function calls 
  defp compile({name, meta, args}, ctx), do: compile_call(name, args, meta, ctx)

  defp compile_literal(term, _ctx) when is_primitive(term), do: AST.Literal.new(term)

  defp compile_literal(term, ctx) when is_list(term),
    do: AST.Literal.new(:array, Enum.map(term, &compile(&1, ctx)))

  defp compile_literal(:{}, args, ctx),
    do: AST.Literal.new(:array, Enum.map(args, &compile(&1, ctx)))

  defp compile_literal(:%{}, args, ctx),
    do:
      AST.Literal.new(
        :object,
        Enum.map(args, fn {k, v} -> {compile(k, ctx), compile(v, ctx)} end)
      )

  defp compile_identifier(type, name, _ctx), do: AST.Identifier.new(type, name)

  defp compile_block(body, ctx), do: compile_block(body, [], ctx)

  defp compile_block([], _acc, _ctx), do: AST.Block.new([])
  defp compile_block([last], acc, ctx), do: AST.Block.new(Enum.reverse(acc), compile(last, ctx))
  defp compile_block([node | rest], acc, ctx), do: compile_block(rest, [compile(node, ctx) | acc])

  # JavaScript operator precedences
  # Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Operator_precedence#table
  @call_prec {:left, 17}
  @prefix_prec {:unary, 14}
  @exp_prec {:right, 13}
  @factor_prec {:left, 12}
  @term_prec {:left, 11}
  @bshift_prec {:left, 10}
  @comparison_prec {:left, 9}
  @equality_prec {:left, 8}
  @band_prec {:left, 7}
  @bxor_prec {:left, 6}
  @bor_prec {:left, 5}
  @and_prec {:left, 4}
  @or_prec {:left, 3}
  @assign_prec {:right, 2}

  @precedences %{
    # prefix includes unary +, -, and !
    :prefix => @prefix_prec,
    :call => @call_prec,
    :. => @call_prec,
    :** => @exp_prec,
    :* => @factor_prec,
    :/ => @factor_prec,
    :+ => @term_prec,
    :- => @term_prec,
    :"<<" => @bshift_prec,
    :">>" => @bshift_prec,
    :>>> => @bshift_prec,
    :< => @comparison_prec,
    :> => @comparison_prec,
    :<= => @comparison_prec,
    :>= => @comparison_prec,
    :== => @equality_prec,
    :!= => @equality_prec,
    :=== => @equality_prec,
    :!== => @equality_prec,
    :& => @band_prec,
    :^ => @bxor_prec,
    :| => @bor_prec,
    :&& => @and_prec,
    :|| => @or_prec,
    := => @assign_prec
  }

  defp compile_unary(:not, arg, ctx), do: compile_unary(:!, arg, ctx)

  defp compile_unary(operator, arg, ctx),
    do: AST.Unary.new(operator, compile(arg, Map.put(ctx, :parent, :prefix)))

  defp compile_binary(:and, args, ctx), do: compile_binary(:&&, args, ctx)
  defp compile_binary(:or, args, ctx), do: compile_binary(:||, args, ctx)

  defp compile_binary(operator, [fst, snd], ctx) do
    parent = ctx[:parent]
    branch = ctx[:branch]

    node =
      AST.Binary.new(
        operator,
        compile(fst, %{ctx | parent: operator, branch: :left}),
        compile(snd, %{ctx | parent: operator, branch: :right})
      )

    # check wether we should wrap the node in a group
    if parent do
      {_, prec_o} = get_precedence(operator)
      {assoc_p, prec_p} = get_precedence(parent)

      lower_prec? = prec_o < prec_p
      same_prec? = prec_o == prec_p
      same_assoc? = assoc_p == branch
      wrap_node? = lower_prec? || (same_prec? && !same_assoc?)

      if wrap_node?, do: AST.Group.new(node), else: node
    else
      node
    end
  end

  # Access in an annoymous function call like `foo.()`
  defp compile_access([name], _type, ctx), do: compile(name, ctx)

  # Access an erlang module function like `:mod.fun`
  defp compile_access([mod, name], _type, _ctx) when is_atom(mod) and is_atom(name),
    do: AST.Access.new(AST.Identifier.new(:mod, mod), AST.Identifier.new(:var, name))

  # Field access
  defp compile_access([root, key], :dot = type, ctx),
    do: AST.Access.new(compile(root, ctx), AST.Identifier.new(:var, key), type)

  # Bracket access
  defp compile_access([root, key], :bracket = type, ctx),
    do: AST.Access.new(compile(root, ctx), compile(key, ctx), type)

  # Non-qualified function call like `fun()`
  defp compile_call(name, args, meta, ctx) when is_atom(name),
    do: AST.Call.new(AST.Identifier.new(:var, name), Enum.map(args, &compile(&1, ctx)), meta)

  # All other calls
  defp compile_call(name, args, meta, ctx),
    do: AST.Call.new(compile(name, ctx), Enum.map(args, &compile(&1, ctx)), meta)

  defp precedences, do: @precedences
  defp get_precedence(op), do: Map.get(precedences(), op, {:unary, 0})
end
