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

    def start_battle(battle_id) do
      process_name = {:via, Registry, {@registry_name, battle_id}}
      child_spec = {Battle, {battle_id, process_name}}
      DynamicSupervisor.start_child(@sup_name, child_spec)
    end

    def find_battle(battle_id) do
      case Registry.lookup(@registry_name, battle_id) do
        [{pid, _}] -> {:ok, pid}
        [] -> {:error, :not_found}
      end
    end

    @impl true
    def init(_) do
      Logger.info("#{@sup_name} has started from #{inspect(self())}")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end

  defmodule BattleManager do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
    end

    def start_battle(battle_id) do
      GenServer.call(__MODULE__, {:start_room, battle_id})
    end

    @impl true
    def init(_) do
      state = %{
        battles: []
      }

      Logger.info("BattleManager has started with state #{inspect(state)}")
      {:ok, state}
    end

    @impl true
    def handle_call({:start_room, battle_id}, _from, %{battles: battles} = state) do
      {:ok, _} = Sup.start_battle(battle_id)
      state = %{state | battles: [battle_id | battles]}
      Logger.info("BattleManager has started battle #{battle_id}, state #{inspect(state)}")
      {:reply, :ok, state}
    end

    # Catch all
    def handle_call(message, _from, state) do
      Logger.warning("BattleManager unknown call #{inspect(message)}")
      {:noreply, state}
    end
  end
end
