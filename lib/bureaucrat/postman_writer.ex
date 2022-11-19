defmodule WebDoc.PostmanWriter do
  @moduledoc """
  Writes a Postman Collection v2.1 json file.
  [JSON Schema](https://schema.postman.com/json/collection/v2.1.0/docs/index.html)
  """

  alias Bureaucrat.JSON

  def write(records, path) do
    json = build_collection(records, path)
    file = File.open!(path <> ".json", [:write, :utf8])
    IO.puts(file, JSON.encode!(json, pretty: true))
    File.close(file)
  end

  defp build_collection(records, path) do
    info = %{
      name: path |> Path.basename(".json") |> Macro.camelize(),
      schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }

    items =
      records
      |> group_records()
      |> Enum.map(fn {_controller, actions} ->
        title = actions |> List.first() |> elem(1) |> List.first() |> human_controller_name()
        %{name: title, item: build_actions(actions)}
      end)

    %{item: items, info: info}
  end

  defp build_actions(actions) do
    Enum.map(actions, fn {_action, records} ->
      %{
        name: records |> List.first() |> build_path(),
        request: build_request(records),
        response: build_responses(records)
      }
    end)
  end

  defp group_records(records) do
    records
    |> Bureaucrat.Util.stable_group_by(&get_controller/1)
    |> Enum.map(fn {controller, records} ->
      {controller, Bureaucrat.Util.stable_group_by(records, &get_action/1)}
    end)
  end

  defp get_action(record), do: record.private.phoenix_action
  defp get_controller(record), do: record.private.phoenix_controller

  defp human_controller_name(record) do
    controller = record |> get_controller() |> Atom.to_string()

    controller_name =
      case controller |> String.trim_trailing("Controller") |> String.split(".") do
        [_elixir, _app_name | controller_name] when controller_name != [] -> controller_name
        [_elixir | controller_name] when controller_name != [] -> controller_name
        erlang_module -> erlang_module
      end

    controller_name |> Enum.uniq() |> Enum.join(" ")
  end

  defp build_request([record | _] = records) do
    %{
      method: record.method,
      url: build_url(records),
      body: build_req_body(records),
      auth: build_auth(records)
    }
  end

  defp build_url([record | _] = records) do
    path = build_path(record)
    host = "{{host}}"

    %{
      raw: host <> "/" <> path,
      host: [host],
      path: String.split(path, "/"),
      query: records |> Enum.map(&URI.decode_query(&1.query_string)) |> build_key_value(),
      variable: records |> Enum.map(& &1.path_params) |> build_key_value()
    }
  end

  defp build_path(record) do
    path_keys = Map.new(record.path_params, fn {k, v} -> {v, k} end)
    ["" | paths] = String.split(record.request_path, "/")

    Enum.map_join(paths, "/", fn subpath ->
      key = path_keys[subpath]
      if key, do: ":" <> key, else: subpath
    end)
  end

  defp build_req_body(records) do
    %{
      mode: "formdata",
      formdata: records |> Enum.map(& &1.body_params) |> build_key_value()
    }
  end

  defp build_auth(records) do
    has_bearer =
      Enum.all?(records, fn record ->
        record
        |> Plug.Conn.get_req_header("authorization")
        |> Enum.any?()
      end)

    if has_bearer do
      %{type: "bearer", bearer: [%{key: "token", value: "{{token}}"}]}
    else
      %{type: "noauth"}
    end
  end

  # set disabled to key-value that isn't present on all maps
  defp build_key_value(maps) do
    all_keys = maps |> Enum.flat_map(fn map -> Map.keys(map) end) |> Enum.uniq()
    disabled_keys = maps |> Enum.flat_map(fn map -> all_keys -- Map.keys(map) end) |> MapSet.new()

    maps
    |> Enum.flat_map(fn map -> Map.to_list(map) end)
    |> Enum.uniq_by(fn {k, _v} -> k end)
    |> Enum.map(fn {k, v} ->
      if is_binary(k) and k =~ "_id" do
        {k, "{{#{k}}}"}
      else
        {k, v}
      end
    end)
    |> Enum.map(fn {k, v} -> %{key: k, value: v, disabled: k in disabled_keys} end)
  end

  defp build_responses(records) do
    Enum.map(records, fn record ->
      body =
        record.resp_body != "" && record.resp_body |> JSON.decode!() |> JSON.encode!(pretty: true)

      %{
        body: body,
        code: record.status,
        header: Enum.map(record.resp_headers, fn {k, v} -> %{key: k, value: v} end),
        name: build_description(record),
        originalRequest: build_request([record]),
        status: Plug.Conn.Status.reason_phrase(record.status),
        _postman_previewlanguage: "json"
      }
    end)
  end

  defp build_description(record) do
    action = record |> get_action() |> Atom.to_string()
    description = record.assigns.bureaucrat_opts[:description]

    description =
      if String.starts_with?(description, action) and String.contains?(description, " ") do
        [_ | description] = String.split(description, " ")
        Enum.join(description, " ")
      else
        description
      end

    "#{Integer.to_string(record.status)}: " <> description
  end
end
