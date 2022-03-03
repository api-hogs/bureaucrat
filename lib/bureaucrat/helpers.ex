defmodule Bureaucrat.Helpers do
  alias Phoenix.Socket.{Broadcast, Message, Reply}
  alias Phoenix.Socket

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
  Adds a Phoenix.Socket connection to the generated documentation.

  The name of the test currently being executed will be used as a description for the example.
  """
  defmacro doc_connect(
             handler,
             params,
             connect_info \\ quote(do: %{})
           ) do
    if endpoint = Module.get_attribute(__CALLER__.module, :endpoint) do
      quote do
        {status, socket} =
          unquote(Phoenix.ChannelTest).__connect__(unquote(endpoint), unquote(handler), unquote(params), unquote(connect_info))

        doc({status, socket, unquote(handler), unquote(params), unquote(connect_info)})
        {status, socket}
      end
    else
      raise "module attribute @endpoint not set for socket/2"
    end
  end

  @doc """
  Adds a Phoenix.Socket.Message to the generated documentation.

  The name of the test currently being executed will be used as a description for the example.
  """
  defmacro doc_push(socket, event) do
    quote bind_quoted: [socket: socket, event: event] do
      ref = make_ref()
      message = %Message{event: event, topic: socket.topic, ref: ref, payload: Phoenix.ChannelTest.__stringify__(%{})}
      doc(message, [])
      send(socket.channel_pid, message)
      ref
    end
  end

  defmacro doc_push(socket, event, payload) do
    quote bind_quoted: [socket: socket, event: event, payload: payload] do
      ref = make_ref()
      message = %Message{event: event, topic: socket.topic, ref: ref, payload: Phoenix.ChannelTest.__stringify__(payload)}
      doc(message, [])
      send(socket.channel_pid, message)
      ref
    end
  end

  defmacro doc_broadcast_from(socket, event, message) do
    quote bind_quoted: [socket: socket, event: event, message: message] do
      %{pubsub_server: pubsub_server, topic: topic, transport_pid: transport_pid} = socket
      broadcast = %Broadcast{topic: topic, event: event, payload: message}
      doc(broadcast, [])
      Phoenix.Channel.Server.broadcast_from(pubsub_server, transport_pid, topic, event, message)
    end
  end

  defmacro doc_broadcast_from!(socket, event, message) do
    quote bind_quoted: [socket: socket, event: event, message: message] do
      %{pubsub_server: pubsub_server, topic: topic, transport_pid: transport_pid} = socket
      broadcast = %Broadcast{topic: topic, event: event, payload: message}
      doc(broadcast, [])
      Phoenix.Channel.Server.broadcast_from!(pubsub_server, transport_pid, topic, event, message)
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
  defmacro doc(conn, desc) when is_binary(desc) do
    quote bind_quoted: [conn: conn, desc: desc] do
      doc(conn, description: desc)
    end
  end

  defmacro doc(conn, opts) when is_list(opts) do
    # __CALLER__returns a `Macro.Env` struct
    #   -> https://hexdocs.pm/elixir/Macro.Env.html
    mod = __CALLER__.module
    fun = __CALLER__.function |> elem(0) |> to_string
    # full path as binary
    file = __CALLER__.file
    line = __CALLER__.line

    titles = Application.get_env(:bureaucrat, :titles)

    opts =
      opts
      |> Keyword.put_new(:description, format_test_name(fun))
      |> Keyword.put_new(:group_title, group_title_for(mod, titles))
      |> Keyword.put(:module, mod)
      |> Keyword.put(:file, file)
      |> Keyword.put(:line, line)

    quote bind_quoted: [conn: conn, opts: opts] do
      default_operation_id = get_default_operation_id(conn)

      opts =
        opts
        |> Keyword.put_new(:operation_id, default_operation_id)

      Bureaucrat.Recorder.doc(conn, opts)
      conn
    end
  end

  def format_test_name("test " <> name), do: name

  def group_title_for(_mod, []), do: nil

  def group_title_for(mod, [{other, path} | paths]) do
    if String.replace_suffix(to_string(mod), "Test", "") == to_string(other) do
      path
    else
      group_title_for(mod, paths)
    end
  end

  def get_default_operation_id(%Plug.Conn{private: private}) do
    %{phoenix_controller: elixir_controller, phoenix_action: action} = private
    controller = elixir_controller |> to_string() |> String.trim("Elixir.")

    "#{controller}.#{action}"
  end

  def get_default_operation_id(%Message{topic: topic, event: event}) do
    "#{topic}.#{event}"
  end

  def get_default_operation_id(%Broadcast{topic: topic, event: event}) do
    "#{topic}.#{event}"
  end

  def get_default_operation_id(%Reply{topic: topic}) do
    "#{topic}.reply"
  end

  def get_default_operation_id({_, _, %Socket{endpoint: endpoint}}) do
    "#{endpoint}.reply"
  end

  def get_default_operation_id({_, %Socket{endpoint: endpoint}, _, _, _}) do
    "#{endpoint}.connect"
  end

  @doc """
  Helper function for adding the phoenix_controller and phoenix_action keys to
  the private map of the request that's coming from the test modules.

  For example:

  test "all items - unauthenticated", %{conn: conn} do
    conn
    |> get(item_path(conn, :index))
    |> plug_doc(module: __MODULE__, action: :index)
    |> doc()
    |> assert_unauthenticated()
  end

  The request from this test will never touch the controller that's being tested,
  because it is being piped through a plug that authenticates the user and redirects
  to another page. In this scenario, we use the plug_doc function.
  """
  def plug_doc(conn, module: module, action: action) do
    controller_name = module |> to_string |> String.trim("Test")

    conn
    |> Plug.Conn.put_private(:phoenix_controller, controller_name)
    |> Plug.Conn.put_private(:phoenix_action, action)
  end
end
