# SwaggerDemo

A simple demo API app to show phoenix_swagger, bureaucrat and slate in action.

## Get started

 * Install dependencies: `mix deps.get`
 * Create database: `mix ecto.setup`
 * Compile source: `mix compile`
 * Generate Swagger: `mix swagger`
 * Generate Bureaucrat docs: `DOC=1 mix test`
 * Generate Slate HTML: `cd doc; bundle install; bundle exec middleman build; cd ../`
 * Copy docs into phoenix app: `cp -R doc/build/* priv/static/doc`
 * Start Server: `mix phoenix.server`
 * View docs at [`localhost:4000/doc/index.html`](http://localhost:4000/doc/index.html) from your browser
