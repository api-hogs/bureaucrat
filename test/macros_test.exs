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
end
