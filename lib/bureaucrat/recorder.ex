defmodule Bureaucrat.Recorder do
  use GenServer

  @server __MODULE__

  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, [], name: @server)
  end

  def doc(conn, desc) do
    GenServer.cast(@server, {:doc, conn, desc})
  end

  def write_docs do
    GenServer.call(@server, :write_docs)
  end

  def init([]) do
    {:ok, []}
  end

  def handle_cast({:doc, conn, desc}, records) do
    conn = Plug.Conn.assign(conn, :bureaucrat_desc, desc)
    {:noreply, [conn | records]}
  end

  def handle_call(:write_docs, _from, records) do
    Bureaucrat.MarkdownWriter.write_docs(records)
    {:reply, :ok, records}
  end
end
