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

  describe "description" do
    test "is generated from a test description", context do
      get(context.conn, "/hello")
      [conn] = Recorder.get_records()
      assert conn.assigns.bureaucrat_desc == "description is generated from a test description"
    end

    test "is generated when the request is made from another function", context do
      hello_request(context.conn)
      [conn] = Recorder.get_records()
      assert conn.assigns.bureaucrat_desc == "description is generated when the request is made from another function"
    end

    test "is not auto-generated when one is provided", context do
      hello_request(context.conn, description: "custom description")
      [conn] = Recorder.get_records()
      assert conn.assigns.bureaucrat_desc == "custom description"
    end

    defp hello_request(conn, opts \\ []) do
      case Keyword.fetch(opts, :description) do
        :error -> get(conn, "/hello")
        {:ok, description} -> conn |> get_undocumented("/hello") |> doc(description: description)
      end
    end
  end
end
