defmodule Runic.AST.Primitive do
  alias Runic.Codegen.Documentable

  @type t :: %__MODULE__{
          value: String.t()
        }

  defstruct [:value]

  def new(nil) do
    %__MODULE__{value: "null"}
  end

  def new(number) when is_number(number) do
    %__MODULE__{value: to_string(number)}
  end

  def new(boolean) when is_boolean(boolean) do
    %__MODULE__{value: to_string(boolean)}
  end

  def new(string) when is_binary(string) do
    %__MODULE__{value: ~s("#{escape_string(string)}")}
  end

  def new(atom) when is_atom(atom) do
    new(to_string(atom))
  end

  defimpl Documentable do
    import Runic.Codegen.Document

    def to_document(primitive) do
      text(primitive.value)
    end
  end

  # Escapes quotes (double and single), double backslashes and others.
  # This function is adapated from Phoenix.HTML library.
  # See: https://github.com/phoenixframework/phoenix_html/blob/v4.1.1/lib/phoenix_html.ex#L309
  defp escape_string(data) when is_binary(data),
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
end
