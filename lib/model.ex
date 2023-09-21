defmodule TicTacToe.Model do
  @type sign() :: :cross | :zero
  @type field() :: nonempty_list()

  defmodule Player do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            name: String.t(),
            sign: Model.sign()
          }
    defstruct [:id, :name, :sign]
  end

  defmodule BattleField do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            field: Model.field()
          }
    defstruct [:id, :field]
  end

  defmodule Game do
    @type t() :: %__MODULE__{
            id: pos_integer(),
            players: [Player.t()],
            battle_field: BattleField.t(),
            turn_of_the_move: Player.t(),
            winner: Player.t()
          }
    defstruct [:id, :players, :battle_field, :turn_of_the_move, :winner]
  end
end
