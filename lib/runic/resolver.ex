defprotocol Runic.Resolver do
  alias Runic.AST

  @spec resolve(AST.t()) :: AST.t()
  def resolve(ast)
end

defimpl Runic.Resolver, for: Any do
  def resolve(ast), do: ast
end

defimpl Runic.Resolver, for: Runic.AST.Identifier do
  # TODO: check if an identifier is valid in JavaScript
  def resolve(ast) do
    ast
  end
end

defimpl Runic.Resolver, for: Runic.AST.Group do
  def resolve(group) do
    %Runic.AST.Group{group | node: Runic.Resolver.resolve(group.node)}
  end
end

defimpl Runic.Resolver, for: Runic.AST.Block do
  def resolve(block) do
    %Runic.AST.Block{
      block
      | body: Enum.map(block.body, &Runic.Resolver.resolve/1),
        return: Runic.Resolver.resolve(block.return)
    }
  end
end

defimpl Runic.Resolver, for: Runic.AST.Unary do
  def resolve(unary) do
    %Runic.AST.Unary{unary | value: Runic.Resolver.resolve(unary.value)}
  end
end

defimpl Runic.Resolver, for: Runic.AST.Binary do
  def resolve(binary) do
    %Runic.AST.Binary{
      binary
      | left: Runic.Resolver.resolve(binary.left),
        right: Runic.Resolver.resolve(binary.right)
    }
  end
end

defimpl Runic.Resolver, for: Runic.AST.Access do
  def resolve(access) do
    %Runic.AST.Access{access | root: Runic.Resolver.resolve(access.root)}
  end
end

defimpl Runic.Resolver, for: Runic.AST.Call do
  # Dot access like `foo.bar` is always parsed as a function call without parentheses,
  # but we always see it as a field access rather than a function call
  def resolve(%{name: %Runic.AST.Access{} = access, no_parens: true}) do
    Runic.Resolver.resolve(access)
  end

  def resolve(call) do
    %Runic.AST.Call{
      call
      | name: Runic.Resolver.resolve(call.name),
        args: Enum.map(call.args, &Runic.Resolver.resolve/1)
    }
  end
end
