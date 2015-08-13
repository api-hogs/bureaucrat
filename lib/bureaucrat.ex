defmodule Bureaucrat do
  def start do
    {:ok, _} = Bureaucrat.Recorder.start_link
  end

  def doc(conn, desc \\ nil) do
    Bureaucrat.Recorder.doc(conn, desc)
    conn
  end
end
