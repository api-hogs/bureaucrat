defmodule Bureaucrat.Formatter do
  use GenEvent

  def init(config) do
    {:ok, config}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, _config) do
    Bureaucrat.Recorder.write_docs
    :remove_handler
  end

  def handle_event(_event, config) do
    {:ok, config}
  end
end
