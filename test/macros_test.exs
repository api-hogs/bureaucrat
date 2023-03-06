# Inspired by `Phoenix.Test.ConnTest`

defmodule Bureaucrat.MacrosTest.CatchAll do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Bureaucrat.MacrosTest.Router do
  use Phoenix.Router
  scope("/", do: forward("/", Bureaucrat.MacrosTest.CatchAll))
end

defmodule Bureaucrat.MacrosTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest, only: :functions
  import Bureaucrat.Helpers
  import Bureaucrat.Macros
  alias Bureaucrat.MacrosTest.Router
  alias Bureaucrat.Recorder

  @moduletag :capture_log
  Application.put_env(:phoenix, Bureaucrat.MacrosTest.Endpoint, [])

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :phoenix
    def init(opts), do: opts
    def call(conn, :set), do: resp(conn, 200, "ok")

    def call(conn, opts) do
      put_in(super(conn, opts).private[:endpoint], opts)
      |> Router.call(Router.init([]))
    end
  end

  @endpoint Endpoint

  setup_all do
    Endpoint.start_link()
    :ok
  end

  setup _context do
    Application.stop(:bureaucrat)
    Bureaucrat.start()

    conn =
      build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> Plug.Conn.put_private(:phoenix_controller, FooController)
      |> Plug.Conn.put_private(:phoenix_action, :bar)

    {:ok, conn: conn}
  end

  for method <- [:get, :post, :put, :delete] do
    @method method
    test "#{method} macro records connection", %{conn: conn} do
      assert [] = Recorder.get_records()
      unquote(@method)(conn, "/hello", %{foo: "bar"})
      assert [_conn] = Recorder.get_records()
    end
  end

  for method <- [:get_undocumented, :post_undocumented, :put_undocumented, :delete_undocumented, :options, :connect, :trace, :head] do
    @method method
    test "#{method} macro does not record connection", %{conn: conn} do
      unquote(@method)(conn, "/hello", %{foo: "bar"})
      assert [] = Recorder.get_records()
    end
  end

  # If the request doesn't have a `phoenix_action` or `phoenix_controller`, we show an error.
  # This might happen in practice if the request is halted by a Plug before reaching the controller,
  # but we will simulate it by simply not including `phoenix_action` or `phoenix_controller` on `conn`.
  for method <- [:get, :post, :put, :delete] do
    @method method
    test "#{method} macro raises with a message if no Phoenix controller" do
      conn =
        build_conn()
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> Plug.Conn.put_private(:phoenix_action, :bar)

      error = assert_raise RuntimeError, fn -> unquote(@method)(conn, "/", %{foo: "bar"}) end

      assert error.message =~ "Bureaucrat couldn't find a controller and/or action for this request"
    end

    test "#{method} macro raises with a message if no Phoenix action" do
      conn =
        build_conn()
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> Plug.Conn.put_private(:phoenix_controller, FooController)

      error = assert_raise RuntimeError, fn -> unquote(@method)(conn, "/", %{foo: "bar"}) end

      assert error.message =~ "Bureaucrat couldn't find a controller and/or action for this request"
    end
  end

  # We want to raise an error when Phoenix.ConnTest macros are called outside a `test` block.
  # This test mimics a userland test that calls Phoenix.ConnTest.{get, post, put, delete}
  # and asserts that a RuntimeError is raised when compiling the code.
  # This is counterintuitive, but remember that some of Bureaucrat's runtime is during test compilation.
  for method <- [:get, :post, :put, :delete] do
    @method method
    test "Raises runtime error with message when calling #{@method} outside a `test` block" do
      module_name = :"RuntimeErrorTest#{@method |> Atom.to_string() |> Macro.camelize()}"

      ast =
        quote do
          defmodule unquote(module_name) do
            use ExUnit.Case, async: false
            import Phoenix.ConnTest, only: :functions
            import Bureaucrat.Helpers
            import Bureaucrat.Macros

            @endpoint false

            test "won't compile because it calls Phoenix.ConnTest.#{unquote(@method)} in private function" do
              private_caller()
            end

            defp private_caller() do
              unquote(@method)(:fake_conn, "/hello", %{foo: "bar"})
            end
          end
        end

      error = assert_raise RuntimeError, fn -> Code.eval_quoted(ast) end

      assert error.message =~ "It looks like you called a `Phoenix.ConnTest` macro inside `private_caller`."
    end
  end
end
