Bureaucrat
==========

Bureaucrat is a library that lets you generate API documentation of your Phoenix
app from tests.


Installation
------------

First, add Bureaucrat to your `mix.exs` dependencies:

```elixir
defp deps do
  [{:bureaucrat, "~> 0.0.3"}]
end
```

Then, update your dependencies:

```
$ mix deps.get
```

Next, in your `test/test_helper.exs` you should start Bureaucrat and configure
ExUnit to use it's formatter. You would probably like to keep the default
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
To generate docs from a connection, pass it to `doc/1` funciton:

```elixir
test "GET /api/v1/products" do
  conn = conn()
      |> get("/api/v1/products")
      |> doc
  assert conn.status == 200
end
```

Then, run the tests. At the end of the test suite, Bureaucrat will generate
the documentation file(s) from all of the captured connections.

The default output file is `web/controllers/README.md`.
