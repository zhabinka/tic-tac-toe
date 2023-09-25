defmodule TicTacToe.Battle do
  require Logger

  use GenServer

  def start_link({battle_id, process_name}) do
    GenServer.start_link(__MODULE__, battle_id, name: process_name)
  end

  @impl true
  def init(battle_id) do
    state = %TicTacToe.Model.Battle{
      id: battle_id,
      players: [],
      field: {{nil, nil, nil}, {nil, nil, nil}, {nil, nil, nil}},
      current_move: nil,
      winner: nil
    }

    Logger.info("Battle has started #{inspect(state)}")
    {:ok, state}
  end
end
