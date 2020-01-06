Bureaucrat
==========

Bureaucrat is a library that lets you generate API documentation of your Phoenix
app from tests.


Installation
------------

First, add Bureaucrat to your `mix.exs` dependencies:

```elixir
defp deps do
  [{:bureaucrat, "~> 0.2.6"}]
end
```

Bureaucrat needs a json library and defaults to Poison. It must be added as a dependency:

```elixir
defp deps do
  [
    {:bureaucrat, "~> 0.2.5"},
    {:poison, "~> 3.0"}
  ]
end
```

Then, update your dependencies:

```
$ mix deps.get
```

Next, in your `test/test_helper.exs` you should start Bureaucrat and configure
ExUnit to use its formatter. You would probably like to keep the default
`ExUnit.CLIFormatter` as well.

```elixir
Bureaucrat.start
ExUnit.start(formatters: [ExUnit.CLIFormatter, Bureaucrat.Formatter])
```

And finally, import Bureaucrat helpers in `test/support/conn_case.ex`:

```elixir
defmodule Spell.ConnCase do
  using do
    quote do
      import Bureaucrat.Helpers
    end
  end
end
```

To generate Phoenix channel documentation, import the helpers in `test/support/channel_case.ex` alike.

Usage
-----

Bureaucrat collects data from connection structs used in tests.
If you want a connection to be documented, pass it to the `doc/1` function:

```elixir
test "GET /api/v1/products" do
  conn = conn()
      |> get("/api/v1/products")
      |> doc
  assert conn.status == 200
end
```

Additional options can be passed to the backend formatter:

```elixir
test "GET /api/v1/products" do
  conn = conn()
      |> get("/api/v1/products")
      |> doc(description: "List all products", operation_id: "list_products")
  assert conn.status == 200
end

```

Then, to generate the documentation file(s) run `DOC=1 mix test`.
The default output file is `web/controllers/README.md`.

### Custom intro sections

To add a custom intro section, for each output file, bureaucrat will look for an __intro markdown file__ in the output directory,
named like the output file with a `_intro` or `_INTRO` suffix (before `.md`, if present), e.g.

  * `web/controllers/README` -> `web/controllers/README_INTRO`
  * `web/controllers/readme.md` -> `web/controllers/readme_intro.md`

Currently the supported writers are the default `Bureaucrat.MarkdownWriter` and `Bureaucrat.ApiBlueprintWriter`.

Documenting Phoenix Channels
----------------------------

Bureaucrat can also generate documentation for messages, replies and broadcasts in [Phoenix Channels](http://www.phoenixframework.org/docs/channels).

Results of `assert_push`, `assert_broadcast` and the underlying `assert_receive` (if used for messages or broadcasts) can be passed to the `doc` function.

To document usage of [Phoenix.ChannelTest](https://hexdocs.pm/phoenix/Phoenix.ChannelTest.html) helpers `push`, `broadcast_from` and `broadcast_from!`, Bureaucrat includes documenting alternatives, prefixed with `doc_`:
  * `doc_push`
  * `doc_broadcast_from`
  * `doc_broadcast_from!`

```elixir
test "message:new broadcasts are pushed to the client", %{socket: socket} do
  doc_broadcast_from! socket, "message:new", %{body: "Hello there!", timestamp: 1483971926566, user: "marla"}
  assert_push("message:new", %{body: "Hello there!", timestamp: 1483971926566, user: "marla"})
  |> doc
end
```

Channels docs output is currently only supported by the `Bureaucrat.MarkdownWriter` and only to the `default_path` (see [Configuration](#configuration) below).

Swagger & Slate Integration
---------------------------

Bureaucrat comes with the `Bureaucrat.SwaggerSlateMarkdownWriter` backend that will merge test examples with a swagger spec to produce markdown files that can be processed with the [slate](https://github.com/lord/slate) static generator.

To configure swagger integration, first write a swagger file by hand or generate one using [phoenix_swagger](https://github.com/xerions/phoenix_swagger). In the example below, the swagger file exists in the project at `priv/static/swagger.json`.

Clone the slate project into a directory in your project:

```
git clone --shallow https://github.com/lord/slate doc
```

Configure Bureaucrat `writer`, `default_path` and `swagger`:

```elixir
Bureaucrat.start(
  env_var: "DOC",
  writer: Bureaucrat.SwaggerSlateMarkdownWriter,
  default_path: "doc/source/index.html.md",
  swagger: "priv/static/swagger.json" |> File.read!() |> Poison.decode!())
```

Within each test, link the test example to a swagger operation by passing an `operation_id` to the `doc` helper:

```elixir
test "creates and renders resource when data is valid", %{conn: conn} do
  conn =
    conn
    |> post(user_path(conn, :create), user: @valid_attrs)
    |> doc(operation_id: "create_user")

  assert json_response(conn, 201)["data"]["id"]
  assert Repo.get_by(User, @valid_attrs)
end
```

Now generate documentation with `DOC=1 mix test`.

Use slate to convert the markdown to HTML:

```
cd doc
bundle install
bundle exec middleman build
```

To serve the documentation directly from your application, copy the slate build output to your `priv/static` directory:

```
mkdir priv/static/doc
cp -R doc/build/* priv/static/doc
```

Whitelist the `doc` directory for static assets in the `Plug.Static` configuration:

```elixir
plug Plug.Static,
  at: "/", from: :swagger_demo, gzip: false,
  only: ~w(css doc fonts images js favicon.ico robots.txt)
```

Run your application with `mix phoenix.server` and visit `http://localhost:4000/doc/index.html` to see your documentation.

For a full example see the `examples/swagger_demo` project.

API Blueprint support
---------------------------

Bureaucrat also supports generating markdown files that are formatted in the [API Blueprint](https://apiblueprint.org/) syntax.
Simply set the `Bureaucrat.ApiBlueprintWriter` in your configuration file and run the usual:

```
DOC=1 mix test
```

After the markdown file has been successfully generated you can use [aglio](https://github.com/danielgtaylor/aglio) to produce the html file:

```
aglio -i web/controllers/api/v1/documentation.md -o web/controllers/api/v1/documentation.html
```

### API Blueprint usage note
If you're piping through custom plugs than can prevent the HTTP requests to land in the controllers (authentication, authorization) and you want to document these cases you'll need the `plug_doc()` helper:

```
describe "unauthenticated user" do
  test "GET all items", %{conn: conn} do
    conn
    |> get(item_path(conn, :index))
    |> plug_doc(module: __MODULE__, action: :index)
    |> doc()
    |> assert_unauthenticated()
  end
end
```

Without the `plug_doc()` helper Bureaucrat doesn't know the `phoenix_controller` (since the request never landed in the controller) and an error is raised: `** (RuntimeError) GET all items (/api/v1/items) doesn't have required :phoenix_controller key. Have you forgotten to plug_doc()?`

Configuration
-------------

The configuration options can be passed to `Bureaucrat.start`:

```elixir
Bureaucrat.start(
 writer: Bureaucrat.MarkdownWriter,
 default_path: "web/controllers/README.md",
 paths: [],
 titles: [],
 env_var: "DOC",
 json_library: Poison
)
```

The available options are:

* `:writer`: The module used to generate docs from the list of captured
connections.
* `:default_path`: The path where the docs are written by default.
* `:paths`: Allows you to specify different doc paths for some of your modules.
For example `[{YourApp.Api.V1, "web/controllers/api/v1/README.md"}]` will
cause the docs for controllers under `YourApp.Api.V1` namespace to
be written to `web/controllers/api/v1/README.md`.
* `:titles`: Allows you to specify explicit titles for some of your modules.
For example `[{YourApp.Api.V1.UserController, "API /v1/users"}]` will
change the title (Table of Contents entry and heading) for this controller.
* `:prefix`: Allows you to remove the prefix of the test module names
* `:env_var`: The environment variable used as a flag to trigger doc generation.
* `:json_library`: The JSON library to use. Poison (the default) and Jason both work.
