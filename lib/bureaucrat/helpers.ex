defmodule Bureaucrat.Helpers do
  alias Phoenix.Socket.{Broadcast, Message}

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
      Phoenix.Channel.Server.broadcast_from pubsub_server, transport_pid, topic, event, message
    end
  end

  defmacro doc_broadcast_from!(socket, event, message) do
    quote bind_quoted: [socket: socket, event: event, message: message] do
      %{pubsub_server: pubsub_server, topic: topic, transport_pid: transport_pid} = socket
      broadcast = %Broadcast{topic: topic, event: event, payload: message}
      doc(broadcast, [])
      Phoenix.Channel.Server.broadcast_from! pubsub_server, transport_pid, topic, event, message
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
    mod  = __CALLER__.module
    fun  = __CALLER__.function |> elem(0) |> to_string
    line = __CALLER__.line

    opts =
      opts
      |> Keyword.put_new(:description, format_test_name(fun))
      |> Keyword.put(:module, mod)
      |> Keyword.put(:line, line)

    quote bind_quoted: [conn: conn, opts: opts] do
      Bureaucrat.Recorder.doc(conn, opts)
      conn
    end
  end

  def format_test_name("test " <> name), do: name
end
