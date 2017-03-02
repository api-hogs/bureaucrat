Bureaucrat
==========

Bureaucrat is a library that lets you generate API documentation of your Phoenix
app from tests.


Installation
------------

First, add Bureaucrat to your `mix.exs` dependencies:

```elixir
defp deps do
  [{:bureaucrat, "~> 0.1.4"}]
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

Currently only supported by the (default) `Bureaucrat.MarkdownWriter`.

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

Configuration
-------------

The configuration options can be passed to `Bureaucrat.start`:

```elixir
Bureaucrat.start(
 writer: Bureaucrat.MarkdownWriter,
 default_path: "web/controllers/README.md",
 paths: [],
 env_var: "DOC"
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
* `:env_var`: The environment variable used as a flag to trigger doc generation.
