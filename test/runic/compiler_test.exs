defmodule Runic.CompilerTest do
  use ExUnit.Case

  import Runic.Compiler, only: [compile_quoted: 2]

  describe "literals" do
    test "primitives" do
      assert_compiled(1, "1")
      assert_compiled(1.0, "1.0")
      assert_compiled(nil, "null")
      assert_compiled(true, "true")
      assert_compiled(false, "false")
      assert_compiled(:foo, ~s("foo"))
      assert_compiled("foo", ~s("foo"))
    end

    test "aliased module" do
      assert_compiled(quote(do: Mod), "Mod")
      assert_compiled(quote(do: Mod.Foo), "Mod$Foo")

      alias Bar, as: Foo
      assert_compiled(quote(do: Bar), "Bar")
      assert_compiled(quote(do: Foo), "Bar")
      assert_compiled(quote(do: Foo.Baz), "Bar$Baz")
    end

    test "tuple and list" do
      assert_compiled(quote(do: {}), "[]")
      assert_compiled(quote(do: {true, false}), "[true, false]")
      assert_compiled(quote(do: {1, 2, 3}), "[1, 2, 3]")

      assert_compiled(quote(do: []), "[]")
      assert_compiled(quote(do: [1, 2, 3]), "[1, 2, 3]")
    end

    test "maps with string or atom key" do
      assert_compiled(quote(do: %{}), "{}")
      assert_compiled(quote(do: %{foo: :bar}), ~s({"foo": "bar"}))
      assert_compiled(quote(do: %{"foo" => "baz"}), ~s({"foo": "baz"}))
    end

    test "maps with computed key" do
      assert_compiled(quote(do: %{foo => 233}), "{[foo]: 233}")
      assert_compiled(quote(do: %{(1 + 2) => 233}), "{[1 + 2]: 233}")
      assert_compiled(quote(do: %{[] => 233}), "{[[]]: 233}")
      assert_compiled(quote(do: %{%{foo: :bar} => 233}), ~s({[{"foo": "bar"}]: 233}))
    end
  end

  describe "access and function call" do
    test "field dot access" do
      assert_compiled(quote(do: foo.bar), "foo.bar")
      assert_compiled(quote(do: foo.bar.baz), "foo.bar.baz")
    end

    test "bracket access" do
      assert_compiled(quote(do: foo[0]), "foo[0]")
      assert_compiled(quote(do: foo[:bar]), ~s(foo["bar"]))
      assert_compiled(quote(do: foo[nil]), ~s(foo[null]))
      assert_compiled(quote(do: foo[1 + 2]), ~s(foo[1 + 2]))
    end

    test "non-qualified function call" do
      assert_compiled(quote(do: foo), "foo")
      assert_compiled(quote(do: foo()), "foo()")
    end

    test "qualified function call" do
      assert_compiled(quote(do: :mod.fun()), "mod.fun()")
      assert_compiled(quote(do: :mod.fun(233)), "mod.fun(233)")
      assert_compiled(quote(do: Mod.fun()), "Mod.fun()")
      assert_compiled(quote(do: Mod.fun(foo)), "Mod.fun(foo)")
    end
  end

  describe "macro expansion" do
    test "imported macro call" do
    end

    test "qualified macro call" do
    end
  end

  defp assert_compiled(quoted, expected) do
    assert compile_quoted(quoted, __ENV__) == expected
  end
end
