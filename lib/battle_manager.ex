defmodule TicTacToe.BattleManager do
  require Logger
  use GenServer

  alias TicTacToe.{Battle, BattleSup}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def create_battle(session) do
    GenServer.call(__MODULE__, {:create_battle, session})
  end

  @impl true
  def init(_) do
    state = %{}

    Logger.info("BattleManager has started with state #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:create_battle, session}, _from, state) do
    case Map.fetch(state, :battle_pid) do
      {:ok, battle_pid} ->
        Battle.prepare_battle(battle_pid, session, state.session)
        Logger.info("BattleManager prepare battle #{inspect(battle_pid)}")
        {:reply, {:ok, battle_pid}, %{}}

      :error ->
        {:ok, battle_pid} = BattleSup.create_battle()
        Logger.info("BattleManager create Battle #{inspect(battle_pid)}")
        state = %{battle_pid: battle_pid, session: session}
        {:reply, {:ok, battle_pid, :waiting_for_opponent}, state}
    end
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warning("BattleManager unknown call #{inspect(message)}")
    {:noreply, state}
  end
end
