defmodule Bureaucrat.Helpers do
  def doc(conn, desc \\ nil) do
    Bureaucrat.Recorder.doc(conn, desc)
    conn
  end
end
