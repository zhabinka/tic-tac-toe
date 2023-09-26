defmodule TicTacToe.Battle do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  @impl true
  def init(_) do
    state = %TicTacToe.Model.Battle{
      # id: battle_id,
      players: [],
      field: {{nil, nil, nil}, {nil, nil, nil}, {nil, nil, nil}},
      current_move: nil,
      winner: nil
    }

    Logger.info("Battle has started #{inspect(state)}")
    {:ok, state}
  end
end
