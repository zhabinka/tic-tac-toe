defmodule TicTacToe.BattleManager do
  require Logger
  use GenServer

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
    case Map.fetch(state, :opponent_session) do
      {:ok, opponent} ->
        {:ok, battle_pid} = TicTacToe.BattleSup.create_battle()
        TicTacToe.Battle.prepare_battle(battle_pid, opponent, session)
        Logger.info("BattleManager create battle #{inspect(battle_pid)}")
        {:reply, {:ok, battle_pid}, %{}}

      :error ->
        IO.puts("BattleManager add session #{inspect(session)} in Battle state #{inspect(state)}")
        {:reply, {:ok, :waiting_for_opponent}, Map.put(state, :opponent_session, session)}
    end
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warning("BattleManager unknown call #{inspect(message)}")
    {:noreply, state}
  end
end
