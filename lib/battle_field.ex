defmodule TicTacToe.Game do
  require Logger

  defmodule Battle do
    use GenServer

    def start_link({battle_id, process_name}) do
      GenServer.start_link(__MODULE__, battle_id, name: process_name)
    end

    @impl true
    def init(battle_id) do
      state = %TicTacToe.Model.Battle{
        id: battle_id,
        players: [],
        field: [["", "", ""], ["", "", ""], ["", "", ""]],
        turn_of_the_move: nil,
        winner: nil
      }

      Logger.info("Battle has started #{inspect(state)}")
      {:ok, state}
    end
  end

  defmodule Sup do
    use DynamicSupervisor

    @sup_name :battle_sup
    @registry_name :battle_registry

    def start_link(_) do
      Registry.start_link(keys: :unique, name: @registry_name)
      DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
    end

    @impl true
    def init(_) do
      Logger.info("#{@sup_name} has started from #{inspect(self())}")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end
end
