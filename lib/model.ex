defmodule TicTacToe.Model do
  @type user_role() :: :user | :players
  @type sign() :: :cross | :zero
  @type battle_field() :: nonempty_list()
  @type session_status() :: :wait_opponent | :game_on | :game_off | :game_over

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
            turn_of_the_move: Player.t(),
            winner: User.t()
          }
    defstruct [:id, :players, :field, :turn_of_the_move, :winner]
  end

  defmodule Session do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            battle: Battle.t(),
            has_opponent: true | false,
            status: Model.session_status()
          }
    defstruct [:id, :battle, :has_opponent, :status]
  end
end
