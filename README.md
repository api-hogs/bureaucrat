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

Usage
-----

Bureaucrat collects data from connection structs used in tests.
If you want a connection to be documented, pass it to the `doc/1` funciton:

```elixir
test "GET /api/v1/products" do
  conn = conn()
      |> get("/api/v1/products")
      |> doc
  assert conn.status == 200
end
```

Then, to generate the documentation file(s) run `DOC=1 mix test`.
The default output file is `web/controllers/README.md`.

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
