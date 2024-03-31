defprotocol Caffe.Resolver do
  alias Caffe.AST

  @spec resolve(AST.t()) :: AST.t()
  def resolve(ast)
end

defimpl Caffe.Resolver, for: Any do
  def resolve(ast), do: ast
end

defimpl Caffe.Resolver, for: Caffe.AST.Identifier do
  # TODO: check if an identifier is valid in JavaScript
  def resolve(ast) do
    ast
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Group do
  def resolve(group) do
    %Caffe.AST.Group{group | node: Caffe.Resolver.resolve(group.node)}
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Block do
  def resolve(block) do
    %Caffe.AST.Block{
      block
      | body: Enum.map(block.body, &Caffe.Resolver.resolve/1),
        return: Caffe.Resolver.resolve(block.return)
    }
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Unary do
  def resolve(unary) do
    %Caffe.AST.Unary{unary | value: Caffe.Resolver.resolve(unary.value)}
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Binary do
  def resolve(binary) do
    %Caffe.AST.Binary{
      binary
      | left: Caffe.Resolver.resolve(binary.left),
        right: Caffe.Resolver.resolve(binary.right)
    }
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Access do
  def resolve(access) do
    %Caffe.AST.Access{access | root: Caffe.Resolver.resolve(access.root)}
  end
end

defimpl Caffe.Resolver, for: Caffe.AST.Call do
  def resolve(%{name: %Caffe.AST.Access{} = access, no_parens: true}) do
    Caffe.Resolver.resolve(access)
  end

  def resolve(call) do
    %Caffe.AST.Call{
      call
      | name: Caffe.Resolver.resolve(call.name),
        args: Enum.map(call.args, &Caffe.Resolver.resolve/1)
    }
  end
end
