defmodule TicTacToe.UsersDatabase do
  alias TicTacToe.Model.User

  def get_users() do
    [
      %User{id: 1, name: "Fedor", role: :user},
      %User{id: 2, name: "Anna", role: :user},
      %User{id: 3, name: "Vera", role: :user},
      %User{id: 4, name: "Nina", role: :user},
      %User{id: 5, name: "Nikita", role: :user}
    ]
  end

  def get_by_name(name, users \\ get_users()) do
    users
    |> Enum.filter(fn user -> String.capitalize(name) == user.name end)
    |> case do
      [user] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end
end
