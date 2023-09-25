defmodule TicTacToe.Model do
  @type user_role() :: :user | :players
  @type sign() :: :cross | :zero
  @type battle_field() :: nonempty_list()
  @type battle_status() :: :wait_opponent | :game_on | :game_off | :game_over

  defmodule User do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            name: String.t(),
            sign: Model.sign(),
            role: Model.user_role()
          }
    defstruct [:id, :name, :role, :sign]
  end

  defmodule Battle do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            players: [User.t()],
            field: Model.battle_field(),
            current_move: Player.t(),
            status: Model.battle_status(),
            winner: User.t()
          }
    defstruct [:id, :players, :field, :current_move, :status, :winner]
  end

  defmodule Session do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            battle: Battle.t(),
            has_opponent: true | false
          }
    defstruct [:id, :battle, :has_opponent]
  end
end
