defmodule Runic.SpecialForms do
  @builtins [
    new: 2,
    get: 2,
    set: 3,
    send: 3,
    await: 1,
    typeof: 1,
    shl: 2,
    shr: 2,
    ushr: 2,
    band: 2,
    bxor: 2,
    bor: 2
  ]

  Enum.each(@builtins, fn {name, arity} ->
    def unquote(name)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
      do: error(unquote({name, arity}))
  end)

  defp error({name, arity}) do
    raise(
      "Runic function #{inspect(__MODULE__)}.#{name}/#{arity} cannot be called in BEAM runtime."
    )
  end
end
