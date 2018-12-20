defmodule Bureaucrat.JSON do
  @moduledoc """
  Wrapper around the configured JSON library.
  The default is Poison, but it can be configured to e.g. Jason with:

      config :bureaucrat, :json_library, Jason
  """

  def encode(value, options \\ []) do
    json_library().encode(value, options)
  end

  def encode!(value, options \\ []) do
    json_library().encode!(value, options)
  end

  def decode(value, options \\ []) do
    json_library().decode(value, options)
  end

  def decode!(value, options \\ []) do
    json_library().decode!(value, options)
  end

  defp json_library do
    Application.get_env(:bureaucrat, :json_library, Poison)
  end
end
