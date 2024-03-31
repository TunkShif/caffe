defmodule Caffe do
  @moduledoc """
  Documentation for `Caffe`.
  """

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :caffe_function, accumulate: true)
      @before_compile Caffe.Builder

      import Caffe, only: [defun: 2, defun: 3, defunp: 2, defunp: 3]
    end
  end

  @type options :: [async: boolean()]

  defmacro defun(head, opts \\ [], do: body) do
    quote do
      @caffe_function unquote(Macro.escape({head, body, opts}))
      def unquote(head) do
        raise "Caffe module function cannot be called in BEAM runtime."
        unquote(body)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __caffe_env__, do: __ENV__

      def __caffe_functions__, do: @caffe_function
    end
  end
end
