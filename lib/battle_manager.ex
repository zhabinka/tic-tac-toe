defmodule TicTacToe.BattleManager do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def start_battle(battle_id) do
    GenServer.call(__MODULE__, {:start_room, battle_id})
  end

  # NOTE: Как сделать общее имя хранилища для разных модулей?
  def find_battle(battle_id) do
    case Registry.lookup(:battle_registry, battle_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
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
    {:ok, _} = TicTacToe.BattleSup.start_battle(battle_id)
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
