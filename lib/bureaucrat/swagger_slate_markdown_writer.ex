defmodule Bureaucrat.SwaggerSlateMarkdownWriter do
@moduledoc """
This markdown writer integrates swagger information and outputs in a slate-friendly markdown format.
It requires that the decoded swagger data be available via Application.get_env(:bureaucrat, :swagger),
eg by passing it as an option to the Bureaucrat.start/1 function.
"""

  alias Plug.Conn

  # pipeline-able puts
  defp puts(file, string) do
    IO.puts(file, string)
    file
  end

  @doc """
  Writes a list of Plug.Conn records to the given file path.

  Each Conn should have request and response data populated,
   and the private.phoenix_controller, private.phoenix_action values set for linking to swagger.
  """
  def write(records, path) do
    {:ok, file} = File.open path, [:write, :utf8]
    swagger = Application.get_env(:bureaucrat, :swagger)

    file
    |> write_overview(swagger)
    |> write_authentication(swagger)
    |> write_models(swagger)

    records
      |> tag_records(swagger)
      |> group_records()
      |> Enum.each(fn {tag, records_by_operation_id} ->
           write_operations_for_tag(file, tag, records_by_operation_id, swagger)
         end)
  end

  @doc """
  Writes the document title and api summary description.

  This corresponds to the info section of the swagger document.
  """
  def write_overview(file, swagger) do
    info = swagger["info"]
    file
    |> puts("""
    ---
    title: #{info["title"]}

    search: true
    ---

    # #{info["title"]}

    #{info["description"]}
    """)
  end

  @doc """
  Writes the authentication details to the given file.

  This corresponds to the securityDefinitions section of the swagger document.
  """
  def write_authentication(file, %{"security" => security} = swagger) do
    file
    |> puts("# Authentication\n")

    # TODO: Document token based security
    Enum.each security, fn securityRequirement ->
       name = Map.keys(securityRequirement) |> List.first
       definition = swagger["securityDefinitions"][name]
       file
       |> puts("## #{definition["type"]}\n")
       |> puts("#{definition["description"]}\n")
     end
     file
  end
  def write_authentication(file, _), do: file

  @doc """
  Writes the API request/response model schemas to the given file.

  This corresponds to the definitions section of the swagger document.
  Each top level definition will be written as a table.
  Nested objects are flattened out to reduce the number of tables being produced.
  """
  def write_models(file, swagger) do
    puts(file, "# Models\n")
    Enum.each swagger["definitions"], fn definition ->
      write_model(file, swagger, definition)
    end
    file
  end

  @doc """
  Writes a single API model schema to the given file.

  Most of the work is delegated to the write_model_properties/3 recurive function.
  The example json is output before the table just so slate will align them.
  """
  def write_model(file, swagger, {name, model_schema}) do

    file
    |> puts("## #{name}\n")
    |> puts("#{model_schema["description"]}")
    |> write_model_example(model_schema)
    |> puts("|Property|Description|Type|Required|")
    |> puts("|--------|-----------|----|--------|")
    |> write_model_properties(swagger, model_schema)
    |> puts("")
  end

  def write_model_example(file, %{"example" => example}) do
    json = Poison.encode!(example, pretty: true)
    file
    |> puts("\n```json")
    |> puts(json)
    |> puts("```\n")
  end
  def write_model_example(file, _) do
    puts(file, "")
  end

  @doc """
  Writes the fields of the given model to file.

  prefix is output before each property name to enable nested objects to be flattened.
  """
  def write_model_properties(file, swagger, model_schema, prefix \\ "") do
    {objects, primitives} = model_schema["properties"]
      |> Enum.partition(fn {_key, schema} -> schema["type"] == "object" end)

    ordered = Enum.concat(primitives, objects)

    Enum.each ordered, fn {property, property_details} ->
      {property_details, type} = resolve_type(swagger, property_details)
      required? = is_required(property, model_schema)
      write_model_property(file, swagger, "#{prefix}#{property}", property_details, type, required?)
    end
    file
  end

  def resolve_type(swagger, %{"$ref" => schema_ref}) do
    schema_name = String.replace_prefix(schema_ref, "#/definitions/", "")
    property_details = swagger["definitions"][schema_name]
    type = schema_ref_to_link(schema_ref)
    {property_details, type}
  end
  def resolve_type(_swagger, property_details) do
    {property_details, property_details["type"]}
  end

  def write_model_property(file, swagger, property, property_details, "object", _required?) do
    write_model_properties(file, swagger, property_details, "#{property}.")
  end

  def write_model_property(file, swagger, property, property_details, "array", required?) do
    schema = property_details["items"]

    #TODO: handle arrays with inline schema
    schema_ref = if schema != nil, do: schema["$ref"], else: nil
    type = if schema_ref != nil, do: "array(#{schema_ref_to_link(schema_ref)})", else: "array(any)"
    write_model_property(file, swagger, property, property_details, type, required?)
  end

  def write_model_property(file, _swagger, property, property_details, type, required?) do
    puts(file, "|#{property}|#{property_details["description"]}|#{type}|#{required?}|")
  end

  defp is_required(property, %{"required" => required}), do: property in required
  defp is_required(_property, _schema), do: false

  # Convert a schema reference eg, #/definitions/User to a markdown link
  def schema_ref_to_link("#/definitions/" <> type) do
    "[#{type}](##{String.downcase(type)})"
  end

  @doc """
  Populate each test record with private.swagger_tag and private.operation_id from swagger.
  """
  def tag_records(records, swagger) do
    tags_by_operation_id =
      for {_path, actions} <- swagger["paths"],
          {_action, details} <- actions do
        [first_tag|_] = details["tags"]
        {details["operationId"], first_tag}
      end
      |> Enum.into(%{})

    Enum.map(records, &(tag_record(&1, tags_by_operation_id)))
  end

  @doc """
  Tag a single record with swagger tag and operation_id.
  """
  def tag_record(conn, tags_by_operation_id) do
    operation_id = conn.assigns.bureaucrat_opts[:operation_id]
    Conn.put_private(conn, :swagger_tag, tags_by_operation_id[operation_id])
  end

  @doc """
  Group a list of tagged records, first by tag, then by operation_id.
  """
  def group_records(records) do
    by_tag = Enum.group_by(records, &(&1.private.swagger_tag))
    Enum.map by_tag, fn {tag, records_with_tag} ->
      by_operation_id = Enum.group_by(records_with_tag, &(&1.assigns.bureaucrat_opts[:operation_id]))
      {tag, by_operation_id}
    end
  end

  @doc """
  Writes the API details and exampels for operations having the given tag.

  tag roughly corresponds to a phoenix controller, eg "Users"
  records_by_operation_id are the examples collected during tests, grouped by operationId (Controller.action)
  """
  def write_operations_for_tag(file, tag, records_by_operation_id, swagger) do
    tag_details = swagger["tags"] |> Enum.find(&(&1["name"] == tag))

    file
    |> puts("# #{tag}\n")
    |> puts("#{tag_details["description"]}\n")

    Enum.each records_by_operation_id, fn {operation_id, records} ->
      write_action(file, operation_id, records, swagger)
    end
    file
  end

  @doc """
  Writes all examples of a given operation (Controller action) to file.
  """
  def write_action(file, operation_id, records, swagger) do
    details = find_operation_by_id(swagger, operation_id)
    puts(file, "## #{details["summary"]}\n")

    # write examples before params/schemas to get correct alignment in slate
    Enum.each(records, &(write_example(file, &1)))

    file
    |> puts("#{details["description"]}\n")
    |> write_parameters(details)
    |> write_responses(details)
  end

  @doc """
  Find the details of an API operation in swagger by operationId
  """
  def find_operation_by_id(swagger, operation_id) do
    Enum.flat_map(swagger["paths"], fn {_path, actions} ->
      Enum.map(actions, fn {_action, details} -> details end)
    end)
    |> Enum.find(fn details ->
      details["operationId"] == operation_id
    end)
  end

  @doc """
  Writes the parameters table for given swagger operation to file.

  Uses the vendor extension "x-example" to provide example of each parameter.
  TODO: detailed schema validation rules aren't shown yet (min/max/regex/etc...)
  """
  def write_parameters(file, _ = %{"parameters" => params}) when length(params) > 0 or map_size(params) > 0 do
    file
    |> puts("#### Parameters\n")
    |> puts("| Parameter   | Description | In |Type      | Required | Default | Example |")
    |> puts("|-------------|-------------|----|----------|----------|---------|---------|")

    Enum.each params, fn param ->
      content =
        ["name", "description", "in", "type", "required", "default", "x-example"]
        |> Enum.map(&(param[&1]))
        |> Enum.map(&encode_parameter_table_cell/1)
        |> Enum.join("|")
      puts(file, "|#{content}|")
    end
    puts file, ""
  end
  def write_parameters(file, _), do: file

  # Encode parameter table cell values as strings, using Poison to convert lists/maps
  defp encode_parameter_table_cell(param) when is_map(param) or is_list(param), do: Poison.encode!(param)
  defp encode_parameter_table_cell(param), do: to_string(param)

  @doc """
  Writes the responses table for given swagger operation to file.

  Swagger only allows a single description per status code, which can be limiting
   when trying to describe all possible error responses.  To work around this, add
   markdown links into the description.
  """
  def write_responses(file, swagger_operation) do
    file
    |> puts("#### Responses\n")
    |> puts("| Status | Description | Schema |")
    |> puts("|--------|-------------|--------|")

    Enum.each swagger_operation["responses"], fn {status, response} ->
      ref = get_in response, ["schema", "$ref"]
      schema = if ref, do: schema_ref_to_link(ref), else: ""
      puts(file, "|#{status} | #{response["description"]} | #{schema}|")
    end
  end

  @doc """
  Writes a single request/response example to file
  """
  def write_example(file, record) do
    path = case record.query_string do
      "" -> record.request_path
      str -> "#{record.request_path}?#{str}"
    end

    # Request with path and headers
    file
    |> puts("> #{record.assigns.bureaucrat_desc}\n")
    |> puts("```plaintext")
    |> puts("#{record.method} #{path}")
    |> write_headers(record.req_headers)
    |> puts("```\n")

    # Request Body if applicable
    unless record.body_params == %{} do
      file
      |> puts("```json")
      |> puts("#{Poison.encode!(record.body_params, pretty: true)}")
      |> puts("```\n")
    end

    # Response with status and headers
    file
    |> puts("> Response\n")
    |> puts("```plaintext")
    |> puts("#{record.status}")
    |> write_headers(record.resp_headers)
    |> puts("```\n")

    # Response body
    file
    |> puts("```json")
    |> puts("#{format_resp_body(record.resp_body)}")
    |> puts("```\n")
  end

  @doc """
  Write the list of request/response headers
  """
  def write_headers(file, headers) do
    Enum.each headers, fn {header, value} ->
      puts file, "#{header}: #{value}"
    end
    file
  end

  @doc """
  Pretty-print a JSON response, handling body correctly
  """
  def format_resp_body(string) do
    case string do
      "" -> ""
      _ -> string |> Poison.decode! |> Poison.encode!(pretty: true)
    end
  end
end
