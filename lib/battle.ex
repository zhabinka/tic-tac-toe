defmodule TicTacToe.Battle do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def get_state(battle_pid) do
    GenServer.call(battle_pid, :get_state)
  end

  def get_players(battle_pid) do
    GenServer.call(battle_pid, :get_players)
  end

  def add_player(battle_pid, player) do
    GenServer.call(battle_pid, {:add_player, player})
  end

  def add_sessions(battle_pid, sessions) do
    GenServer.call(battle_pid, {:add_sessions, sessions})
  end

  def add_current_move(battle_pid, session) do
    GenServer.call(battle_pid, {:add_current_move, session})
  end

  def broadcast(battle_pid, event) do
    GenServer.call(battle_pid, {:broadcast, event})
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

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_players, _from, state) do
    {:reply, state.players, state}
  end

  def handle_call({:add_player, player}, _from, state) do
    IO.puts("Before add #{inspect(state)}")
    %TicTacToe.Model.Battle{players: players} = state
    state = %TicTacToe.Model.Battle{state | players: [player | players]}
    IO.puts("After add #{inspect(state)}")
    {:reply, :ok, state}
  end

  def handle_call({:add_sessions, sessions}, _from, state) do
    state = %TicTacToe.Model.Battle{state | sessions: sessions}
    {:reply, :ok, state}
  end

  def handle_call({:add_current_move, session}, _from, state) do
    state = %TicTacToe.Model.Battle{state | current_move: session}
    {:reply, :ok, state}
  end

  def handle_call({:broadcast, event}, _from, state) do
    state = do_broadcast(event, state)
    {:replay, :ok, state}
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warn("Battle unknown call #{inspect(message)}")
    {:reply, {:error, :unknown_call}, state}
  end

  def do_broadcast(event, state) do
    
    Logger.info("Battle do_broadcast to #{inspect state.sessions}: event #{inspect event}")
    Enum.each(
      state.sessions,
      fn session_pid -> TicTacToe.Session.send_event(session_pid, event) end
    )
    state
  end
end
