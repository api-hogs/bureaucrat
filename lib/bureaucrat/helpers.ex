defmodule Bureaucrat.Helpers do
  defmacro doc(conn, desc \\ nil) do
    fun  = __CALLER__.function |> elem(0) |> to_string
    line = __CALLER__.line

    quote bind_quoted: [desc: desc, conn: conn, fun: fun, line: line] do
      Bureaucrat.Recorder.doc(conn, desc || format_test_name(fun), line)
      conn
    end
  end

  def format_test_name("test " <> name), do: name
end
