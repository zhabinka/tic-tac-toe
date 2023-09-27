defmodule TicTacToe.Model do
  @type user_role() :: :user | :players
  @type battle_status() :: :wait_opponent | :game_on | :game_off | :game_over

  @type sign() :: :cross | :zero
  @type cell() :: sign() | nil
  @type row() :: {cell(), cell(), cell()}
  @type battle_field() :: {row(), row(), row()}

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
            sessions: {pid(), pid()},
            field: Model.battle_field(),
            current_move: Player.t(),
            status: Model.battle_status(),
            winner: User.t()
          }
    defstruct [:id, :players, :sessions, :field, :current_move, :status, :winner]
  end

  defmodule Session do
    @type t() :: %__MODULE__{
            session_id: pos_integer(),
            listening_socket: identifier(),
            socket: identifier(),
            user: Player.t(),
            battle_pid: pid(),
            has_opponent: true | false
          }
    defstruct [
      :session_id,
      :listening_socket,
      :socket,
      :user,
      :battle_pid,
      :has_opponent
    ]
  end
end
