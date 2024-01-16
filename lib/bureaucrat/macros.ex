defmodule Bureaucrat.Macros do
  @moduledoc """
  Implements `Phoenix.ConnTest` macros with `&Bureaucrat.Helpers.doc/1` support.
  When `Phoenix.ConnTest` macros (get, post, put...) are called, `doc` helper is automatically called after.
  If you don't wish to document a certain request, use `get_undocumented` or any other `_undocumented` macro.
  It automatically skips documentation if halted by a Plug.

  When a request is called from inside a private function instead of a test block, `Bureaucrat` can't
  find the test name to use on the documentation, and raises. In this case, use the `_undocumented`
  version to bypass the documentation, or send the request from the test block instead of private function.

  - Automatically documents: get, post, put, patch and delete requests
  - Skips documentation for: options, connect, trace and head requests
  - Implements: get_undocumented, post_undocumented, put_undocumented, patch_undocumented and delete_undocumented.

  ## Usage

  On `ConnCase` file, change this

      import Phoenix.ConnTest

  To

      import Phoenix.ConnTest, only: :functions
      import Bureaucrat.Helpers
      import Bureaucrat.Macros
  """

  @doc_http_methods [:get, :post, :put, :patch, :delete]
  @undoc_http_methods [:options, :connect, :trace, :head]

  for method <- @doc_http_methods do
    @doc """
    Dispatches test request with documentation.
    Documents: get, post, put, patch and delete requests.
    """
    defmacro unquote(method)(conn, path_or_action, params_or_body \\ nil) do
      method = unquote(method)

      quote do
        conn =
          Phoenix.ConnTest.dispatch(
            unquote(conn),
            @endpoint,
            unquote(method),
            unquote(path_or_action),
            unquote(params_or_body)
          )

        accept_header = conn |> Plug.Conn.get_req_header("accept") |> List.first() || ""
        content_header = conn |> Plug.Conn.get_req_header("content-type") |> List.first() || ""
        is_json = Enum.any?([accept_header, content_header], &String.contains?(&1, "json"))

        if is_json do
          try do
            doc(conn)
          rescue
            # Bureaucrat fails to get controller/action when request is halted from a plug.
            # In this case, we skip documentation. Here is the reason:
            # https://github.com/api-hogs/bureaucrat/blob/8ac7efd04dafdedfe986ba0032e7cb1cbac1df5d/lib/bureaucrat/helpers.ex#L147
            e in MatchError ->
              conn
          end
        else
          conn
        end
      end
    end
  end

  for method <- @doc_http_methods do
    @doc """
    Dispatches test request without documentation.
    Implements: get_undocumented, post_undocumented, put_undocumented, ..., macros to skip doc.
    """
    method_name = String.to_atom("#{method}_undocumented")

    defmacro unquote(method_name)(conn, path_or_action, params_or_body \\ nil) do
      method = unquote(method)

      quote do
        Phoenix.ConnTest.dispatch(
          unquote(conn),
          @endpoint,
          unquote(method),
          unquote(path_or_action),
          unquote(params_or_body)
        )
      end
    end
  end

  for method <- @undoc_http_methods do
    @doc """
    Dispatches test request without documentation.
    Skips documentation for: options, connect, trace and head requests
    """
    defmacro unquote(method)(conn, path_or_action, params_or_body \\ nil) do
      method = unquote(method)

      quote do
        Phoenix.ConnTest.dispatch(
          unquote(conn),
          @endpoint,
          unquote(method),
          unquote(path_or_action),
          unquote(params_or_body)
        )
      end
    end
  end
end
