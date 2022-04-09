defmodule Bureaucrat.ApiBlueprintWriter do
  alias Bureaucrat.JSON

  def write(records, path) do
    file = File.open!(path, [:write, :utf8])
    records = group_records(records)
    title = Application.get_env(:bureaucrat, :title)
    puts(file, "# #{title}\n\n")
    write_intro(path, file)
    write_api_doc(records, file)
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

  defp write_api_doc(records, file) do
    Enum.each(records, fn {controller, actions} ->
      %{request_path: path} = Enum.at(actions, 0) |> elem(1) |> List.first()
      puts(file, "\n# Group #{controller}")
      puts(file, "## #{controller} [#{path}]")

      Enum.each(actions, fn {action, records} ->
        write_action(action, controller, Enum.reverse(records), file)
      end)
    end)

    puts(file, "")
  end

  defp write_action(action, controller, records, file) do
    test_description = "#{controller} #{action}"
    record_request = Enum.at(records, 0)
    method = record_request.method

    file
    |> puts("### #{test_description} [#{method} #{anchor(record_request)}]")
    |> puts("\n\n #{Keyword.get(record_request.assigns.bureaucrat_opts, :detail, "")}")

    write_parameters(record_request.path_params, file)

    records
    |> sort_by_status_code
    |> Enum.each(&write_example(&1, file))
  end

  defp write_parameters(path_params, _file) when map_size(path_params) == 0, do: nil

  defp write_parameters(path_params, file) do
    file |> puts("\n+ Parameters\n#{formatted_params(path_params)}")

    Enum.each(path_params, fn {param, value} ->
      puts(file, indent_lines(12, "#{param}: #{value}"))
    end)

    file
  end

  defp sort_by_status_code(records) do
    records |> Enum.sort_by(& &1.status)
  end

  defp write_example(record, file) do
    write_request(record, file)
    write_response(record, file)
  end

  defp write_request(record, file) do
    path = get_request_path(record)

    file
    |> puts("\n\n+ Request #{record.assigns.bureaucrat_desc}")
    |> puts("**#{record.method}**&nbsp;&nbsp;`#{path}`\n")

    write_headers(record.req_headers, file)
    write_request_body(record.body_params, file)
  end

  defp get_request_path(record) do
    case record.query_string do
      "" -> record.request_path
      str -> "#{record.request_path}?#{str}"
    end
  end

  defp write_headers(_headers = [], _file), do: nil

  defp write_headers(headers, file) do
    file |> puts(indent_lines(4, "+ Headers\n"))

    Enum.each(headers, fn {header, value} ->
      puts(file, indent_lines(12, "#{header}: #{value}"))
    end)

    file
  end

  defp write_request_body(params, file) do
    case params == %{} do
      true ->
        nil

      false ->
        file
        |> puts(indent_lines(4, "+ Body\n"))
        |> puts(indent_lines(12, format_request_body(params)))
    end
  end

  defp write_response(record, file) do
    file |> puts("\n+ Response #{record.status}\n")
    write_headers(record.resp_headers, file)
    write_response_body(record.resp_body, file)
  end

  defp write_response_body(params, _file) when map_size(params) == 0, do: nil

  defp write_response_body(params, file) do
    file
    |> puts(indent_lines(4, "+ Body\n"))
    |> puts(indent_lines(12, format_response_body(params)))
  end

  def format_request_body(params) do
    {:ok, json} = JSON.encode(params, pretty: true)
    json
  end

  defp format_response_body("") do
    ""
  end

  defp format_response_body(string) do
    {:ok, struct} = JSON.decode(string)
    {:ok, json} = JSON.encode(struct, pretty: true)
    json
  end

  def indent_lines(number_of_spaces, string) do
    String.split(string, "\n")
    |> Enum.map(fn a -> String.pad_leading("", number_of_spaces) <> a end)
    |> Enum.join("\n")
  end

  def formatted_params(uri_params) do
    Enum.map(uri_params, &format_param/1) |> Enum.join("\n")
  end

  def format_param(param) do
    "    + #{URI.encode(elem(param, 0))}: `#{URI.encode(elem(param, 1))}`"
  end

  def anchor(record = %{path_params: path_params}) when map_size(path_params) == 0 do
    record.request_path
  end

  def anchor(record) do
    Enum.join([""] ++ set_params(record), "/")
  end

  defp set_params(record) do
    Enum.flat_map(record.path_info, fn part ->
      case Enum.find(record.path_params, fn {_key, val} -> val == part end) do
        {param, _} -> ["{#{param}}"]
        nil -> [part]
      end
    end)
  end

  defp puts(file, string) do
    IO.puts(file, string)
    file
  end

  def controller_name(module) do
    prefix = Application.get_env(:bureaucrat, :prefix)

    Regex.run(~r/#{prefix}(.+)/, module, capture: :all_but_first)
    |> List.first()
    |> String.trim("Controller")
    |> Inflex.pluralize()
  end

  defp group_records(records) do
    by_controller = Bureaucrat.Util.stable_group_by(records, &get_controller/1)

    Enum.map(by_controller, fn {c, recs} ->
      {c, Bureaucrat.Util.stable_group_by(recs, &get_action/1)}
    end)
  end

  defp strip_ns(module) do
    case to_string(module) do
      "Elixir." <> rest -> rest
      other -> other
    end
  end

  defp get_controller({_, opts}), do: opts[:group_title] || String.replace_suffix(strip_ns(opts[:module]), "Test", "")
  defp get_controller(conn), do: conn.assigns.bureaucrat_opts[:group_title] || strip_ns(conn.private.phoenix_controller)

  defp get_action({_, opts}), do: opts[:description]
  defp get_action(conn), do: conn.private.phoenix_action
end
