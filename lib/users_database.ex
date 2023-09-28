defmodule TicTacToe.UsersDatabase do
  alias TicTacToe.Model.User

  def get_users() do
    [
      %User{id: 1, name: "Fedor"},
      %User{id: 2, name: "Anna"},
      %User{id: 3, name: "Vera"},
      %User{id: 4, name: "Nina"},
      %User{id: 5, name: "Nikita"}
    ]
  end

  def find_by_name(name, users \\ get_users()) do
    users
    |> Enum.filter(fn user -> String.capitalize(name) == user.name end)
    |> case do
      [user] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end
end
