defmodule Bureaucrat.Recorder do
  use GenServer

  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def doc(conn, desc) do
    GenServer.cast(__MODULE__, {:doc, conn, desc})
  end

  def write_docs do
    GenServer.call(__MODULE__, :write_docs)
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
