defmodule TicTacToe.Battle do
  require Logger
  use GenServer

  alias TicTacToe.{Session, Model, Field}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def get_state(battle_pid) do
    GenServer.call(battle_pid, :get_state)
  end

  def prepare_battle(battle_pid, session1, session2) do
    GenServer.call(battle_pid, {:prepare_battle, session1, session2})
  end

  def get_field(battle_pid) do
    GenServer.call(battle_pid, {:get_field})
  end

  # TODO : Повторяется задача получение значения поля
  # Подумать, можно ли отрефакторить?
  def get_current_move(battle_pid) do
    GenServer.call(battle_pid, {:get_current_move})
  end

  def get_opponent(battle_pid) do
    GenServer.call(battle_pid, {:get_opponent})
  end

  def make_move(battle_pid, session_pid, cell_number) do
    GenServer.call(battle_pid, {:make_move, session_pid, cell_number})
  end

  def broadcast(battle_pid, event) do
    IO.puts("Battle broadcast #{inspect(battle_pid)}, event #{inspect(event)}")
    GenServer.call(battle_pid, {:broadcast, event})
  end

  @impl true
  def init(_) do
    state = %Model.Battle{
      players: [],
      sessions: [],
      field: {{:f, :f, :f}, {:f, :f, :f}, {:f, :f, :f}},
      status: :game_on,
      opponent: nil,
      current_move: nil,
      winner: nil
    }

    Logger.info("Battle has started")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:prepare_battle, session1, session2}, _from, state) do
    session1 = %Model.Session{session1 | sign: :cross}
    session2 = %Model.Session{session2 | sign: :zero}

    state =
      state
      |> Map.put(:sessions, [session1, session2])
      |> Map.put(:opponent, session2)
      |> Map.put(:current_move, session1)

    {:reply, :ok, state}
  end

  def handle_call({:broadcast, event}, _from, state) do
    IO.puts("Battle call :broadcast #{inspect(event)}")
    state = do_broadcast(event, state)
    {:reply, :ok, state}
  end

  def handle_call({:make_move, session_pid, cell_number}, _from, state) do
    if state.current_move.session_pid == session_pid do
      case Field.add_move_to_field(state.field, cell_number, state.current_move.sign) do
        {:error, :impossible_move} ->
          {:reply, {:error, :impossible_move}, state}

        {:ok, field} ->
          Logger.info("User #{inspect(state.current_move)} add move #{inspect(field)}")
          opponent = state.opponent
          current_move = state.current_move

          state =
            state
            |> Map.put(:field, field)
            |> Map.put(:current_move, opponent)
            |> Map.put(:opponent, current_move)

          {:reply, :ok, state}
      end
    else
      # NOTE : Здесь, вроде, сообщение нужно слать в текущую сессию
      # т.е. state.current_move
      Session.send_event(state.opponent, :waiting_opponent_move)
      {:reply, {:error, :move_order_broken}, state}
    end
  end

  def handle_call({:get_field}, _from, state) do
    {:reply, {:ok, state.field}, state}
  end

  def handle_call({:get_current_move}, _from, state) do
    {:reply, {:ok, state.current_move}, state}
  end

  def handle_call({:get_opponent}, _from, state) do
    {:reply, {:ok, state.opponent}, state}
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warn("Battle unknown call #{inspect(message)}")
    {:reply, {:error, :unknown_call}, state}
  end

  defp do_broadcast(event, state) do
    Logger.info("Battle do_broadcast to #{inspect(state.sessions)}: event #{inspect(event)}")

    Enum.each(
      state.sessions,
      fn session ->
        IO.puts("do_broadcast each: #{inspect(session)}, event #{inspect(event)}")
        Session.send_event(session, event)
      end
    )

    state
  end
end
