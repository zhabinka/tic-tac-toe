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
    state = %{
      sessions: []
    }

    Logger.info("BattleManager has started with state #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:create_battle, session}, _from, %{sessions: sessions} = state) do
    case sessions do
      [] ->
        state = %{state | sessions: [session]}

        IO.puts("BattleManager add session #{inspect(session)} in Battle state #{inspect(state)}")

        {:reply, {:ok, :waiting_for_opponent}, state}

      _ ->
        sessions = [session | state.sessions]
        {:ok, battle_pid} = TicTacToe.BattleSup.create_battle()
        TicTacToe.Battle.add_sessions(battle_pid, sessions)
        TicTacToe.Battle.add_current_move(battle_pid, session)

        Logger.info(
          "BattleManager create battle #{inspect(battle_pid)}, add sessions and current move"
        )

        state = %{state | sessions: []}
        {:reply, {:ok, battle_pid}, state}
    end
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warning("BattleManager unknown call #{inspect(message)}")
    {:noreply, state}
  end
end
