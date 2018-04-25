defmodule Bureaucrat.ApiBlueprintWriter do
  def write(records, path) do
    file = File.open!(path, [:write, :utf8])
    records = group_records(records)
    title = Application.get_env(:bureaucrat, :title)
    puts(file, "# #{title}\n\n")
    write_api_doc(records, file)
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
    path_params = record_request.path_params

    file |> puts("### #{test_description} [#{method} #{anchor(record_request)}]")

    unless path_params == %{} do
      file
      |> puts("\n+ Parameters\n#{formatted_params(path_params)}")

      Enum.each(path_params, fn {param, value} ->
        puts(file, indent_lines(12, "#{param}: #{value}"))
      end)

      file
    end

    Enum.each(records, &write_example(&1, file))
  end

  defp write_example(record, file) do
    path =
      case record.query_string do
        "" -> record.request_path
        str -> "#{record.request_path}?#{str}"
      end

    file
    |> puts("\n\n+ Request #{record.assigns.bureaucrat_desc}")
    |> puts("**#{record.method}**&nbsp;&nbsp;`#{path}`\n")

    unless record.req_headers == [] do
      file
      |> puts(indent_lines(4, "+ Headers\n"))

      Enum.each(record.req_headers, fn {header, value} ->
        puts(file, indent_lines(12, "#{header}: #{value}"))
      end)

      file
    end

    unless record.body_params == %{} do
      file
      |> puts(indent_lines(4, "+ Body\n"))
      |> puts(indent_lines(12, format_body_params(record.body_params)))
    end

    file
    |> puts("\n+ Response #{record.status}\n")

    unless record.resp_headers == [] do
      file
      |> puts(indent_lines(4, "+ Headers\n"))

      Enum.each(record.resp_headers, fn {header, value} ->
        puts(file, indent_lines(12, "#{header}: #{value}"))
      end)

      file
    end

    file
    |> puts(indent_lines(4, "+ Body\n"))
    |> puts(indent_lines(12, format_resp_body(record.resp_body)))
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

  def anchor(record) do
    if record.path_params == %{} do
      record.request_path
    else
      ([""] ++ Enum.drop(record.path_info, -1) ++ ["{id}"]) |> Enum.join("/")
    end
  end

  defp puts(file, string) do
    IO.puts(file, string)
    file
  end

  defp module_name(module) do
    module
    |> to_string
    |> String.split("Elixir.")
    |> List.last()
    |> controller_name()
  end

  def controller_name(module) do
    prefix = Application.get_env(:bureaucrat, :prefix)

    Regex.run(~r/#{prefix}(.+)/, module, capture: :all_but_first)
    |> List.first()
    |> String.trim("Controller")
    |> Inflex.pluralize()
  end

  defp group_records(records) do
    records
    |> Enum.group_by(&module_name(&1.private.phoenix_controller))
    |> Enum.map(fn {controller_name, records} ->
      {controller_name, Enum.group_by(records, & &1.private.phoenix_action)}
    end)
  end
end
