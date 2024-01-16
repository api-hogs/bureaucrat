defmodule Bureaucrat.PostmanWriterTest do
  use ExUnit.Case
  alias Bureaucrat.{JSON, PostmanWriter}

  defp fixture(:record) do
    Phoenix.ConnTest.build_conn()
    |> Plug.Conn.put_private(:phoenix_action, :action_name)
    |> Plug.Conn.put_private(:phoenix_controller, MyApp.FooController)
    |> Plug.Conn.assign(:bureaucrat_opts, description: "returns items")
    |> Plug.Conn.put_status(200)
  end

  setup_all do
    output_dir = "test/output/"
    File.mkdir(output_dir)
    on_exit(fn -> File.rm_rf(output_dir) end)
    [record: fixture(:record)]
  end

  describe "postman writer" do
    test "writes json file", %{record: record} do
      filename = "test/output/test.json"
      PostmanWriter.write([record], filename)
      assert filename |> File.read!() |> JSON.encode!()
    end

    test "writes collection name with the filename", %{record: record} do
      filename = "test/output/foo_bar.json"
      PostmanWriter.write([record], filename)
      json = filename |> File.read!() |> JSON.decode!()
      assert json["info"]["name"] == "FooBar"
    end

    test "writes item name with controller name", %{record: record} do
      filename = "test/output/test.json"
      PostmanWriter.write([record], filename)
      json = filename |> File.read!() |> JSON.decode!()
      assert get_in(json, ["item", Access.at(0), "name"]) == "Elixir MyApp Foo"
    end

    test "writes item name with path", %{record: record} do
      filename = "test/output/test.json"
      PostmanWriter.write([%{record | request_path: "/foobar"}], filename)
      json = filename |> File.read!() |> JSON.decode!()
      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "name"]) == "foobar"
    end

    test "writes request authentication bearer as variable", %{record: record} do
      filename = "test/output/test.json"
      record_auth = Plug.Conn.put_req_header(record, "authorization", "bearer foobar")
      record_noauth = Plug.Conn.put_private(record, :phoenix_action, :action_name2)
      PostmanWriter.write([record_auth, record_noauth], filename)
      json = filename |> File.read!() |> JSON.decode!()

      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "request", "auth", "type"]) ==
               "bearer"

      assert get_in(json, ["item", Access.at(0), "item", Access.at(1), "request", "auth", "type"]) ==
               "noauth"
    end

    test "writes one response per record", %{record: record} do
      filename = "test/output/test.json"
      record1 = Plug.Conn.put_status(record, 201)
      record2 = Plug.Conn.put_status(record, 404)
      PostmanWriter.write([record1, record2], filename)
      json = filename |> File.read!() |> JSON.decode!()

      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "response", Access.at(0), "status"]) ==
               "Created"

      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "response", Access.at(1), "status"]) ==
               "Not Found"
    end

    test "writes json body as list", %{record: record} do
      filename = "test/output/foo_bar.json"

      record =
        Map.replace!(record, :body_params, %{
          "_json" => [
            %{
              "id" => "123",
              "type" => "a_type"
            }
          ]
        })
        |> Map.replace!(:req_headers, [{"content-type", "application/json"}])

      PostmanWriter.write([record], filename)
      json = filename |> File.read!() |> JSON.decode!()

      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "request", "body", "raw"]) |> JSON.decode!() ==
               [
                 %{
                   "id" => "123",
                   "type" => "a_type"
                 },
               ]
    end

    test "writes json body as list when empty list", %{record: record} do
      filename = "test/output/foo_bar.json"

      record =
        Map.replace!(record, :body_params, %{
          "_json" => []
        })
        |> Map.replace!(:req_headers, [{"content-type", "application/json"}])

      PostmanWriter.write([record], filename)
      json = filename |> File.read!() |> JSON.decode!()

      assert get_in(json, ["item", Access.at(0), "item", Access.at(0), "request", "body", "raw"]) |> JSON.decode!() ==
               []
    end
  end
end
