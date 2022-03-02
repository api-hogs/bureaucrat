defmodule Bureaucrat.MarkdownWriter do
  alias Bureaucrat.JSON

  def write(records, path) do
    {:ok, file} = File.open(path, [:write, :utf8])
    records = group_records(records)
    write_intro(path, file)
    write_table_of_contents(records, file)

    Enum.each(records, fn {controller, records} ->
      write_controller(controller, records, file)
    end)
  end

  defp write_intro(path, file) do
    intro_file_path =
      [
        # /path/to/API.md -> /path/to/API_INTRO.md
        String.replace(path, ~r/\.md$/i, "_INTRO\\0"),
        # /path/to/api.md -> /path/to/api_intro.md
        String.replace(path, ~r/\.md$/i, "_intro\\0"),
        # /path/to/API -> /path/to/API_INTRO
        "#{path}_INTRO",
        # /path/to/api -> /path/to/api_intro
        "#{path}_intro"
      ]
      # which one exists?
      |> Enum.find(nil, &File.exists?/1)

    if intro_file_path do
      file
      |> puts(File.read!(intro_file_path))
      |> puts("\n\n## Endpoints\n\n")
    else
      puts(file, "# API Documentation\n")
    end
  end

  defp write_table_of_contents(records, file) do
    Enum.each(records, fn {controller, actions} ->
      anchor = to_anchor(controller)
      puts(file, "  * [#{controller}](##{anchor})")

      Enum.each(actions, fn {action, _} ->
        anchor = to_anchor(controller, action)
        puts(file, "    * [#{action}](##{anchor})")
      end)
    end)

    puts(file, "")
  end

  defp write_controller(controller, records, file) do
    puts(file, "## #{controller}")

    Enum.each(records, fn {action, records} ->
      write_action(action, controller, records, file)
    end)
  end

  defp write_action(action, controller, records, file) do
    anchor = to_anchor(controller, action)
    puts(file, "### <a id=#{anchor}></a>#{action}")
    Enum.each(records, &write_example(&1, file))
  end

  defp write_example({%Phoenix.Socket.Broadcast{topic: topic, payload: payload, event: event}, _}, file) do
    file
    |> puts("#### Broadcast")
    |> puts("* __Topic:__ #{topic}")
    |> puts("* __Event:__ #{event}")

    if payload != %{} do
      file
      |> puts("* __Body:__")
      |> puts("```json")
      |> puts("#{format_body_params(payload)}")
      |> puts("```")
    end
  end

  defp write_example({%Phoenix.Socket.Message{topic: topic, payload: payload, event: event}, _}, file) do
    file
    |> puts("#### Message")
    |> puts("* __Topic:__ #{topic}")
    |> puts("* __Event:__ #{event}")

    if payload != %{} do
      file
      |> puts("* __Body:__")
      |> puts("```json")
      |> puts("#{format_body_params(payload)}")
      |> puts("```")
    end
  end

  defp write_example({%Phoenix.Socket.Reply{payload: payload, status: status}, _}, file) do
    file
    |> puts("#### Reply")
    |> puts("* __Status:__ #{status}")

    if payload != %{} do
      file
      |> puts("* __Body:__")
      |> puts("```json")
      |> puts("#{format_body_params(payload)}")
      |> puts("```")
    end
  end

  defp write_example({{status, payload, %Phoenix.Socket{} = socket}, _}, file) do
    file
    |> puts("#### Join")
    |> puts("* __Topic:__ #{socket.topic}")
    |> puts("* __Receive:__ #{status}")

    if payload != %{} do
      file
      |> puts("* __Body:__")
      |> puts("```json")
      |> puts("#{format_body_params(payload)}")
      |> puts("```")
    end
  end

  defp write_example({{status, %Phoenix.Socket{}, _handler, params, _connect_info}, _}, file) do
    # for connect
    file
    |> puts("#### Connect")

    if params != %{} do
      file
      |> puts("* __Body:__")
      |> puts("```json")
      |> puts("#{format_body_params(params)}")
      |> puts("```")
    end
    |> puts("* __Receive:__ #{status}")
  end

  defp write_example(record, file) do
    path =
      case record.query_string do
        "" -> record.request_path
        str -> "#{record.request_path}?#{str}"
      end

    file
    |> puts("#### #{record.assigns.bureaucrat_desc}")
    |> puts("#{Keyword.get(record.assigns.bureaucrat_opts, :detail, "")}")
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
    |> puts("")
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
    {:ok, json} = JSON.encode(params, pretty: true)
    json
  end

  defp format_resp_body("") do
    ""
  end

  defp format_resp_body(string) do
    {:ok, struct} = JSON.decode(string)
    {:ok, json} = JSON.encode(struct, pretty: true)
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

  defp to_anchor(controller, action), do: to_anchor("#{controller}.#{action}")

  defp to_anchor(name) do
    name
    |> String.downcase()
    |> String.replace(~r/\W+/, "-")
    |> String.replace_leading("-", "")
    |> String.replace_trailing("-", "")
  end

  defp group_records(records) do
    by_controller = Bureaucrat.Util.stable_group_by(records, &get_controller/1)

    Enum.map(by_controller, fn {c, recs} ->
      {c, Bureaucrat.Util.stable_group_by(recs, &get_action/1)}
    end)
  end

  defp get_controller({_, opts}), do: opts[:group_title] || String.replace_suffix(strip_ns(opts[:module]), "Test", "")
  defp get_controller(conn), do: conn.assigns.bureaucrat_opts[:group_title] || strip_ns(conn.private.phoenix_controller)

  defp get_action({_, opts}), do: opts[:description]
  defp get_action(conn), do: conn.private.phoenix_action
end
