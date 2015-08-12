defmodule Bureaucrat.Formatter do
  use GenEvent

  def init(_exunit_config) do
    {:ok, %{}}
  end

  def handle_event({:suite_started, opts}, config) do
    IO.inspect(config)
    {:ok, config}
  end

  def handle_event({:suite_finished, run_us, load_us}, config) do
    :remove_handler
  end

  def handle_event({:case_started, test_case}, config) do
    IO.inspect(test_case.name)
    {:ok, config}
  end

  def handle_event({:case_finished, test_case}, config) do
    {:ok, config}
  end

  def handle_event({:test_started, test_case}, config) do
    IO.inspect(test_case.name)
    {:ok, config}
  end

  def handle_event({:test_finished, test_case}, config) do
    {:ok, config}
  end
end
