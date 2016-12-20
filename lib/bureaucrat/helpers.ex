defmodule Bureaucrat.Helpers do

  @doc """
  Adds a conn to the generated documentation.

  The name of the test currently being executed will be used as a description for the example.
  """
  defmacro doc(conn) do
    quote bind_quoted: [conn: conn] do
      doc(conn, [])
    end
  end

  @doc """
  Adds a conn to the generated documentation

  The description, and additional options can be passed in the second argument:

  ## Examples

      conn = conn()
        |> get("/api/v1/products")
        |> doc("List all products")

      conn = conn()
        |> get("/api/v1/products")
        |> doc(description: "List all products", operation_id: "list_products")
  """
  defmacro doc(conn, desc) when is_binary(desc)  do
    quote bind_quoted: [conn: conn, desc: desc] do
      doc(conn, description: desc)
    end
  end

  defmacro doc(conn, opts) when is_list(opts) do
    fun  = __CALLER__.function |> elem(0) |> to_string
    line = __CALLER__.line

    opts =
      opts
      |> Keyword.put_new(:description, format_test_name(fun))
      |> Keyword.put(:line, line)

    quote bind_quoted: [conn: conn, opts: opts] do
      Bureaucrat.Recorder.doc(conn, opts)
      conn
    end
  end

  def format_test_name("test " <> name), do: name
end
