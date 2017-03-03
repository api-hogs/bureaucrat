defmodule SwaggerDemo.Router do
  use SwaggerDemo.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SwaggerDemo do
    pipe_through :api
    resources "/users", UserController, except: [:new, :edit]
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "SwaggerDemo App"
      },
      tags: [
        %{name: "User", description: "Operations related to Users"}
      ]
    }
  end
end
