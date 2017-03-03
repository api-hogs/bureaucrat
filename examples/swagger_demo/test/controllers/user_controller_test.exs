defmodule SwaggerDemo.UserControllerTest do
  use SwaggerDemo.ConnCase
  import Bureaucrat.Helpers
  alias SwaggerDemo.User

  @valid_attrs %{email: "some content", name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn =
      conn
      |> get(user_path(conn, :index))
      |> doc(operation_id: "list_users")

    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    user = Repo.insert! %User{}
    conn =
      conn
      |> get(user_path(conn, :show, user))
      |> doc(operation_id: "show_user")

    assert json_response(conn, 200)["data"] == %{"id" => user.id,
      "name" => user.name,
      "email" => user.email}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      conn
      |> get(user_path(conn, :show, -1))
      |> doc(operation_id: "show_user")
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn =
      conn
      |> post(user_path(conn, :create), user: @valid_attrs)
      |> doc(operation_id: "create_user")

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(User, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn =
      conn
      |> post(user_path(conn, :create), user: @invalid_attrs)
      |> doc(operation_id: "create_user")

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    user = Repo.insert! %User{}
    conn =
      conn
      |> put(user_path(conn, :update, user), user: @valid_attrs)
      |> doc(operation_id: "update_user")

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(User, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    user = Repo.insert! %User{}
    conn =
      conn
      |> put(user_path(conn, :update, user), user: @invalid_attrs)
      |> doc(operation_id: "update_user")

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    user = Repo.insert! %User{}
    conn =
      conn
      |> delete(user_path(conn, :delete, user))
      |> doc(operation_id: "delete_user")

    assert response(conn, 204)
    refute Repo.get(User, user.id)
  end
end
