defmodule Bureaucrat.Formatter do
  use GenEvent

  def init(_config) do
    {:ok, nil}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, nil) do
    Bureaucrat.Recorder.write_docs
    :remove_handler
  end

  def handle_event(_event, nil) do
    {:ok, nil}
  end
end
