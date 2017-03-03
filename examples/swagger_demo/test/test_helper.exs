Bureaucrat.start(
  writer: Bureaucrat.SwaggerSlateMarkdownWriter,
  default_path: "doc/source/index.html.md",
  env_var: "DOC",
  swagger: "priv/static/swagger.json" |> File.read!() |> Poison.decode!())

Ecto.Adapters.SQL.Sandbox.mode(SwaggerDemo.Repo, :manual)

ExUnit.start(formatters: [ExUnit.CLIFormatter, Bureaucrat.Formatter])
