defmodule Bureaucrat.Formatter do
  use GenEvent

  def init(_config) do
    {:ok, nil}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, nil) do
    env_var = Application.get_env(:bureaucrat, :env_var)
    if System.get_env(env_var), do: generate_docs()
    :remove_handler
  end

  def handle_event(_event, nil) do
    {:ok, nil}
  end

  defp generate_docs do
    records = Bureaucrat.Recorder.get_records
    writer  = Application.get_env(:bureaucrat, :writer)
    grouped =
      records
      |> Enum.sort_by(&line_for/1)
      |> group_by_path

    Enum.map(grouped, fn {path, recs} ->
      apply(writer, :write, [recs, path])
    end)
  end

  defp line_for({_, opts}), do: opts[:line]
  defp line_for(conn), do: -1 * conn.assigns.bureaucrat_line

  defp group_by_path(records) do
    default_path = Application.get_env(:bureaucrat, :default_path)
    paths = Application.get_env(:bureaucrat, :paths)
    Enum.group_by(records, &(path_for(&1, paths, default_path)))
  end

  defp path_for({_, _}, _, default_path), do: default_path
  defp path_for(_record, [], default_path), do: default_path
  defp path_for(record, [{prefix, path} | paths], default_path) do
    module = record.private.phoenix_controller
    if String.starts_with?(to_string(module), to_string(prefix)) do
      path
    else
      path_for(record, paths, default_path)
    end
  end
end
