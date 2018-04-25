defmodule Bureaucrat.ApiBlueprintWriter do
  def write(records, path) do
    {:ok, file} = File.open(path, [:write, :utf8])
    records = group_records(records)
    puts(file, "# API Documentation\n")
    write_table_of_contents(records, file)

    Enum.each(records, fn {controller, records} ->
      write_controller(controller, records, file)
    end)
  end

  defp write_table_of_contents(records, file) do
    Enum.each(records, fn {controller, actions} ->
      anchor = to_anchor(controller)
      puts(file, "* [#{controller}](##{anchor})")

      Enum.each(actions, fn {action, _} ->
        anchor = to_anchor("#{controller}.#{action}")
        puts(file, "  * [#{action}](##{anchor})")
      end)
    end)

    puts(file, "")
  end

  defp write_controller(controller, records, file) do
    puts(file, "## #{to_string(controller)}")

    Enum.each(records, fn {action, records} ->
      write_action(action, controller, records, file)
    end)
  end

  defp write_action(action, controller, records, file) do
    puts(file, "### #{controller}.#{action}")
    Enum.each(records, &write_example(&1, file))
  end

  defp write_example(record, file) do
    path =
      case record.query_string do
        "" -> record.request_path
        str -> "#{record.request_path}?#{str}"
      end

    file
    |> puts("#### #{record.assigns.bureaucrat_desc}")
    |> puts("##### Request")
    |> puts("* __Method:__ #{record.method}")
    |> puts("* __Path:__ #{path}")

    unless record.req_headers == [] do
      file
      |> puts("* __Request headers:__")
      |> puts("```")

      Enum.each(record.req_headers, fn {header, value} ->
        puts(file, "#{header}: #{value}")
      end)

      file
      |> puts("```")
    end

    unless record.body_params == %{} do
      file
      |> puts("* __Request body:__")
      |> puts("```json")
      |> puts("#{format_body_params(record.body_params)}")
      |> puts("```")
    end

    file
    |> puts("##### Response")
    |> puts("* __Status__: #{record.status}")

    unless record.resp_headers == [] do
      file
      |> puts("* __Response headers:__")
      |> puts("```")

      Enum.each(record.resp_headers, fn {header, value} ->
        puts(file, "#{header}: #{value}")
      end)

      file
      |> puts("```")
    end

    file
    |> puts("* __Response body:__")
    |> puts("```json")
    |> puts("#{format_resp_body(record.resp_body)}")
    |> puts("```")
    |> puts("")
  end

  def format_body_params(params) do
    {:ok, json} = Poison.encode(params, pretty: true)
    json
  end

  defp format_resp_body("") do
    ""
  end

  defp format_resp_body(string) do
    {:ok, struct} = Poison.decode(string)
    {:ok, json} = Poison.encode(struct, pretty: true)
    json
  end

  defp puts(file, string) do
    IO.puts(file, string)
    file
  end

  defp strip_ns(module) do
    case to_string(module) do
      "Elixir." <> rest -> rest
      other -> other
    end
  end

  defp to_anchor(name) do
    name
    |> String.downcase()
    |> String.replace(".", "")
  end

  defp group_records(records) do
    by_controller = Enum.group_by(records, &strip_ns(&1.private.phoenix_controller))

    Enum.map(by_controller, fn {c, recs} ->
      {c, Enum.group_by(recs, & &1.private.phoenix_action)}
    end)
  end
end
