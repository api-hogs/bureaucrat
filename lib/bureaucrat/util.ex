defmodule Bureaucrat.Util do
  @moduledoc """
  Some functions used across Bureaucrat internally
  """

  @doc """
  Takes a list of pre-sorted entries and groups them by given function,
  but returns a list of tuples `[{k, v}, ...]` instead of a Map to preserve
  key sort order, which can be given to Enum functions identically.

  Implementation inspired by `Enum.group_by/3`
    -> https://github.com/elixir-lang/elixir/blob/v1.4.2/lib/elixir/lib/enum.ex#L1036
  """
  def stable_group_by(enumerable, key_fun, value_fun \\ fn x -> x end)
      when is_function(key_fun, 1) and is_function(value_fun, 1) do
    Enum.reduce(Enum.reverse(enumerable), [], fn entry, categories ->
      key = key_fun.(entry)
      value = value_fun.(entry)

      case categories do
        # key matches previous key -> add value to previous list
        [{^key, values} | tail] ->
          [{key, [value | values]} | tail]

        # otherwise -> start a new list with this value
        _ ->
          [{key, [value]} | categories]
      end
    end)
  end
end
