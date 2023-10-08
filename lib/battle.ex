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

  def finish_battle(battle_pid, :win, session) do
    GenServer.call(battle_pid, {:finish_battle, :win, session})
  end

  def finish_battle(battle_pid, :draw, session) do
    GenServer.call(battle_pid, {:finish_battle, :win, session})
  end

  def get_field(battle_pid) do
    GenServer.call(battle_pid, {:get_field})
  end

  # TODO : Повторяется задача получение значения поля
  # Подумать, можно ли отрефакторить?
  def get_current_session(battle_pid) do
    GenServer.call(battle_pid, {:get_current_session})
  end

  def get_opponent_session(battle_pid) do
    GenServer.call(battle_pid, {:get_opponent_session})
  end

  def make_move(battle_pid, session_pid, cell_number) do
    GenServer.call(battle_pid, {:make_move, session_pid, cell_number})
  end

  def broadcast(battle_pid, event) do
    Logger.info("Battle broadcast #{inspect(battle_pid)}, event #{inspect(event)}")
    GenServer.call(battle_pid, {:broadcast, event})
  end

  @impl true
  def init(_) do
    state = %Model.Battle{
      sessions: [],
      field: {{:f, :f, :f}, {:f, :f, :f}, {:f, :f, :f}},
      status: :game_on,
      current_session: nil,
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
      |> Map.put(:current_session, session1)

    {:reply, :ok, state}
  end

  def handle_call({:finish_battle, :win, session}, _from, state) do
    state =
      state
      |> Map.put(:status, :game_over)
      |> Map.put(:winner, session)
      |> Map.put(:current_session, nil)

    {:reply, :ok, state}
  end

  def handle_call({:finish_battle, :draw, _session}, _from, state) do
    state =
      state
      |> Map.put(:status, :game_over)
      # |> Map.put(:winner, session)
      |> Map.put(:current_session, nil)

    {:reply, :ok, state}
  end

  def handle_call({:broadcast, event}, _from, state) do
    Logger.info("Battle call :broadcast #{inspect(event)}")
    state = do_broadcast(event, state)
    {:reply, :ok, state}
  end

  def handle_call({:make_move, session_pid, cell_number}, _from, state) do
    opponent = do_get_opponent_session(state)

    if state.current_session.session_pid == session_pid do
      case Field.make_move(state.field, cell_number, state.current_session.sign) do
        {:error, error} ->
          {:reply, {:error, error}, state}

        {:ok, field} ->
          Logger.info("User #{inspect(state.current_session)} add move #{inspect(field)}")

          state =
            state
            |> Map.put(:field, field)
            |> Map.put(:current_session, opponent)

          {:reply, :ok, state}
      end
    else
      # NOTE : Здесь, вроде, сообщение нужно слать в текущую сессию
      # т.е. state.current_session

      Session.send_event(opponent, :waiting_opponent_move)
      {:reply, {:error, :move_order_broken}, state}
    end
  end

  def handle_call({:get_field}, _from, state) do
    {:reply, {:ok, state.field}, state}
  end

  def handle_call({:get_current_session}, _from, state) do
    {:reply, {:ok, state.current_session}, state}
  end

  # TODO : Add tests
  def handle_call({:get_opponent_session}, _from, state) do
    [opponent_session] =
      Enum.filter(state.sessions, fn s -> s.session_pid != state.current_session.session_pid end)

    {:reply, {:ok, opponent_session}, state}
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
        Logger.info("do_broadcast each: #{inspect(session)}, event #{inspect(event)}")
        Session.send_event(session, event)
      end
    )

    state
  end

  def do_get_opponent_session(state) do
    [opponent_session] =
      Enum.filter(state.sessions, fn s -> s.session_pid != state.current_session.session_pid end)

    opponent_session
  end
end
