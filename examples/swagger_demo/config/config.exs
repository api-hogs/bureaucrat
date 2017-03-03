# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :swagger_demo,
  ecto_repos: [SwaggerDemo.Repo]

# Configures the endpoint
config :swagger_demo, SwaggerDemo.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "occcf4JQ1yY8UbMxsqJx0+wxhrQFQMvAJi+mYlaWCSJxmmrgGLyt4eZ9oFhrisRP",
  render_errors: [view: SwaggerDemo.ErrorView, accepts: ~w(json)],
  pubsub: [name: SwaggerDemo.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
