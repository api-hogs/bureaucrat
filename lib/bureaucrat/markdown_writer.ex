defmodule Bureaucrat.MarkdownWriter do
  def write_docs(records) do
    {:ok, file} = File.open "/tmp/doc.md", [:write]
    records = group_records(records)
    puts file, "# API Documentation"
    Enum.each(records, fn {controller, records} ->
      write_controller(controller, records, file)
    end)
    IO.inspect(file, records, [])
  end

  defp write_controller(controller, records, file) do
    puts file, "## " <> to_string(controller)
    Enum.each(records, fn {action, records} ->
      write_action(action, records, file)
    end)
  end

  defp write_action(action, records, file) do
    puts file, "### " <> to_string(action)
    Enum.each(records, &(write_example(&1, file)))
  end

  defp write_example(record, file) do
    file
    |> puts( "#{record.method} #{record.request_path}?#{record.query_string}")
    |> puts( "#{record.status}")
    |> puts( "```json")
    |> puts( "#{format_json(record.resp_body)}")
    |> puts( "```")
    # body_params
    # params
    # req_headers
  end

  defp format_headers(headers) do

  end

  defp format_json(string) do
    {:ok, struct} = Poison.decode(string)
    {:ok, json} = Poison.encode(struct, pretty: true)
    json
  end

  defp puts(file, string) do
    IO.puts(file, string)
    file
  end

  defp group_records(records) do
    by_controller = Enum.group_by(records, &(&1.private.phoenix_controller))
    Enum.map(by_controller, fn {c, recs} ->
      {c, Enum.group_by(recs, &(&1.private.phoenix_action))}
    end)
  end
end
