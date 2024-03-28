defmodule Runic.AST.Literal do
  alias Runic.AST
  alias Runic.Codegen.Documentable

  defmodule Primitive do
    @type t :: %__MODULE__{
            value: String.t()
          }

    defstruct [:value]

    def new(nil) do
      %Primitive{value: "null"}
    end

    def new(number) when is_number(number) do
      %Primitive{value: to_string(number)}
    end

    def new(boolean) when is_boolean(boolean) do
      %Primitive{value: to_string(boolean)}
    end

    def new(string) when is_binary(string) do
      %Primitive{value: ~s("#{escape_string(string)}")}
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

  defmodule Array do
    @type t :: %__MODULE__{
            children: AST.t()
          }
    defstruct [:children]

    def new(children) do
      %Array{children: children}
    end

    defimpl Documentable do
      import Runic.Codegen.Document

      def to_document(array) do
        case array.children do
          [] ->
            text("[]")

          children ->
            [
              text("["),
              nest(list(Enum.map(children, &Documentable.to_document/1))),
              break(),
              text("]")
            ]
        end
      end
    end
  end

  defmodule Object do
    defstruct [:children]

    def new(children) do
      %Object{children: children}
    end

    defimpl Documentable do
      import Runic.Codegen.Document

      def to_document(object) do
        case object.children do
          [] ->
            text("{}")

          children ->
            [
              text("{"),
              nest(
                list(
                  for {key, value} <- children,
                      do: [
                        Documentable.to_document(key),
                        text(": "),
                        Documentable.to_document(value)
                      ]
                )
              ),
              break(),
              text("}")
            ]
        end
      end
    end
  end
end
