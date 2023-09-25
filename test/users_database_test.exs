defmodule TicTacToeTest do
  use ExUnit.Case

  alias TicTacToe.UsersDatabase
  alias TicTacToe.Model.User

  def get_users() do
    [
      %User{id: 1, name: "Alex", role: :user, sign: :cross},
      %User{id: 2, name: "John", role: :user},
      %User{id: 3, name: "Anna", role: :player}
    ]
  end

  test "find user by name" do
    users = get_users()
    assert UsersDatabase.find_by_name("Alex", users) == {:ok, List.first(users)}
    assert UsersDatabase.find_by_name("anna", users) == {:ok, List.last(users)}
    assert UsersDatabase.find_by_name("Helen") == {:error, :not_found}
  end
end
