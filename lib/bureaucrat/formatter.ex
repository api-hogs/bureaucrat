defmodule Bureaucrat.Formatter do
  use GenServer

  def init(_config) do
    {:ok, nil}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    suite_finished()
  end

  def handle_cast({:suite_finished, _times_us}, nil) do
    suite_finished()
  end

  def handle_cast(_event, nil) do
    {:noreply, nil}
  end

  defp suite_finished() do
    env_var = Application.get_env(:bureaucrat, :env_var)
    if System.get_env(env_var), do: generate_docs()

    {:noreply, nil}
  end

  defp generate_docs do
    records = Bureaucrat.Recorder.get_records()
    validate_records(records)
    writer = Application.get_env(:bureaucrat, :writer)

    grouped =
      records
      |> Enum.sort_by(&sort_item_for/1)
      |> group_by_path

    Enum.map(grouped, fn {path, recs} ->
      apply(writer, :write, [recs, path])
    end)
  end

  defp sort_item_for({_, opts}), do: {opts[:file], opts[:line]}
  defp sort_item_for(conn), do: {conn.assigns.bureaucrat_file, conn.assigns.bureaucrat_line}

  defp group_by_path(records) do
    default_path = Application.get_env(:bureaucrat, :default_path)
    paths = Application.get_env(:bureaucrat, :paths)
    Enum.group_by(records, &path_for(&1, paths, default_path))
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

  defp validate_records(records) do
    Enum.each(records, &validate_record/1)
  end

  defp validate_record(%Plug.Conn{private: private} = conn) do
    if Map.has_key?(private, :phoenix_controller) do
      :ok
    else
      error_message =
        "#{conn.assigns.bureaucrat_desc} (#{conn.request_path}) doesn't have required :phoenix_controller key. Have you forgotten to plug_doc()?"

      raise error_message
    end
  end

  defp validate_record(_) do
    :ok
  end
end
