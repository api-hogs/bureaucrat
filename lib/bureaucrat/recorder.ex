defmodule Bureaucrat.Recorder do
  use GenServer

  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def doc(conn, desc, line) do
    GenServer.cast(__MODULE__, {:doc, conn, desc, line})
  end

  def get_records do
    GenServer.call(__MODULE__, :get_records)
  end

  def init([]) do
    {:ok, []}
  end

  def handle_cast({:doc, conn, desc, line}, records) do
    conn =
      conn
      |> Plug.Conn.assign(:bureaucrat_desc, desc)
      |> Plug.Conn.assign(:bureaucrat_line, line)
    {:noreply, [conn | records]}
  end

  def handle_call(:get_records, _from, records) do
    {:reply, records, records}
  end
end
