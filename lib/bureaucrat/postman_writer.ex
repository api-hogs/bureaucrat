defmodule Bureaucrat.PostmanWriter do
  @moduledoc """
  Writes records to Postman Collection v2.1 json file that can be imported directly to Postman.
  [JSON Schema](https://schema.postman.com/json/collection/v2.1.0/docs/index.html)

  Writes one record per postman request and each response is a postman example.
  Test descriptions are used as example names, along with the response status.
  Key ended on `_id` on params/query/body have value substituted by environment `{{variables}}`.
  Params/query/body that aren't sent on all requests are disabled.
  Uses filename as collection name and human controller names as folders for actions.
  Supports bearer authentication header.
  """

  alias Bureaucrat.JSON

  def write(records, path) do
    json = build_collection(records, path)
    file = File.open!(path, [:write, :utf8])
    IO.puts(file, JSON.encode!(json, pretty: true))
    File.close(file)
  end

  defp build_collection(records, path) do
    %{
      item:
        records
        |> group_records()
        |> Enum.map(fn {controller, actions} ->
          content_type =
            records
            |> List.first()
            |> Map.get(:req_headers)
            |> Enum.find_value(fn {header, value} -> if header == "content-type", do: value end)

          %{
            name: controller_name(controller),
            item:
              Enum.map(actions, fn {_action, records} ->
                %{
                  name: records |> List.first() |> build_path(),
                  request: %{
                    auth: build_auth(records),
                    body: build_req_body(records, content_type),
                    header: records |> Enum.map(& &1.req_headers) |> build_key_value(),
                    method: records |> List.first() |> Map.get(:method),
                    url: build_url(records)
                  },
                  response:
                    Enum.map(records, fn record ->
                      %{
                        body: prettify_json(record.resp_body),
                        code: record.status,
                        header: build_key_value([record.resp_headers]),
                        name: build_description(record),
                        originalRequest: %{
                          auth: build_auth([record]),
                          body: build_req_body([record], content_type),
                          header: build_key_value([record.req_headers]),
                          method: record.method,
                          url: build_url([record])
                        },
                        status: Plug.Conn.Status.reason_phrase(record.status),
                        _postman_previewlanguage: "json"
                      }
                    end)
                }
              end)
          }
        end),
      info: %{
        name: path |> Path.basename(".json") |> Macro.camelize(),
        schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
      }
    }
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

  defp controller_name(controller) do
    prefix = Application.get_env(:bureaucrat, :prefix)

    ~r/#{prefix}(.+)/
    |> Regex.run(Atom.to_string(controller), capture: :all_but_first)
    |> List.first()
    |> String.trim_trailing("Controller")
    |> String.replace(".", " ")
  end

  defp prettify_json(nil), do: nil
  defp prettify_json(""), do: ""
  defp prettify_json(json), do: json |> JSON.decode!() |> JSON.encode!(pretty: true)

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

  # Postman only supports one example record. Take the first one and disregard the rest
  defp build_req_body([first_record | _rest], "application/json") do
    %{
      mode: "raw",
      raw: first_record.body_params |> strip__json_key() |> JSON.encode!(),
      options: %{
        raw: %{
          language: "json"
        }
      }
    }
  end

  defp build_req_body(records, _) do
    %{
      mode: "formdata",
      formdata: records |> Enum.map(& &1.body_params) |> build_key_value()
    }
  end

  defp strip__json_key(%{"_json" => params}), do: params |> strip__json_key()
  defp strip__json_key(params), do: params

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

  defp build_key_value([%{"_json" => list}]), do: list |> build_key_value()

  defp build_key_value([first | _] = lists) when is_list(first) do
    lists |> Enum.map(&Map.new/1) |> build_key_value()
  end

  defp build_key_value([]), do: []

  defp build_key_value([first | _] = maps) when is_map(first) do
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
