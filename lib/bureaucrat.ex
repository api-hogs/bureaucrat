defmodule Bureaucrat do
  use Application

  def start(_type, []) do
    children = [Bureaucrat.Recorder]

    opts = [strategy: :one_for_one, name: Bureaucrat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start(options \\ []) do
    Application.start(:bureaucrat)
    configure(options)
    :ok
  end

  defp configure(options) do
    Enum.each(options, fn {k, v} ->
      Application.put_env(:bureaucrat, k, v)
    end)
  end
end
