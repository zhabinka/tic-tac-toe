defmodule TicTacToe.Session do
  require Logger
  use GenServer

  alias TicTacToe.Model.{Session}

  alias TicTacToe.{
    Battle,
    Field,
    UsersDatabase,
    Protocol,
    SessionManager,
    BattleManager
  }

  def start_link({session_id, listening_socket}) do
    GenServer.start_link(__MODULE__, {session_id, listening_socket})
  end

  # NOTE: Сюда лучше передавать pid или всю сессию целиком?
  def send_event(session, event) do
    Logger.info("Session.send_event: #{inspect(session.session_pid)}, #{inspect(event)}")
    GenServer.cast(session.session_pid, {:send_event, event})
  end

  @impl true
  def init({session_id, listening_socket}) do
    state = %Session{
      session_pid: self(),
      listening_socket: listening_socket,
      socket: nil,
      user: nil,
      battle_pid: nil
    }

    Logger.info(
      "Session #{session_id} has started with #{inspect(state.session_pid)}, state #{inspect(state)}"
    )

    {:ok, state, {:continue, :waiting_for_client}}
  end

  @impl true
  def handle_continue(:waiting_for_client, state) do
    Logger.info("Session #{inspect(state.session_pid)} is waiting for client")
    {:ok, socket} = :gen_tcp.accept(state.listening_socket)
    state = %Session{state | socket: socket}
    Logger.info("Session #{inspect(state.session_pid)} got client with #{inspect(state)}")
    send(self(), :receive_data)
    {:noreply, state}
  end

  @impl true
  def handle_info(:receive_data, state) do
    case :gen_tcp.recv(state.socket, 0, 5_000) do
      {:ok, data} ->
        Logger.info("Session #{inspect(state.session_pid)} got data #{data}")

        {response, state} =
          data
          |> String.trim_trailing()
          |> handle_request(state)

        :gen_tcp.send(state.socket, response <> "\n")
        send(self(), :receive_data)
        {:noreply, state}

      {:error, :timeout} ->
        Logger.info("Session #{inspect(state.session_pid)} timeout")
        send(self(), :receive_data)
        {:noreply, state}

      {:error, error} ->
        Logger.warning("Session #{inspect(state.session_pid)} has got error #{inspect(error)}")
        :gen_tcp.close(state.socket)
        state = on_client_disconnect(state)
        {:noreply, state, {:continue, :waiting_for_client}}
    end
  end

  # Catch all
  def handle_info(msg, state) do
    Logger.error("Session #{inspect(self())} unknown info #{inspect(msg)}")
    {:noreply, state}
  end

  # @impl true
  # def handle_call({:send_event, event}, _from, state) do
  #   Logger.info("Session call :send_event, event #{inspect(event)}, #{inspect(state)}")
  #
  #   response = Protocol.serialize(event)
  #   Logger.info("Response #{inspect(response)}")
  #   :gen_tcp.send(state.socket, response <> "\n")
  #   {:reply, :ok, state}
  # end
  #
  # # Catch all
  # def handle_call(message, _from, state) do
  #   Logger.warning("Session unknown call #{inspect(message)}")
  #   {:reply, :ok, state}
  # end

  @impl true
  def handle_cast({:send_event, event}, state) do
    Logger.info("Session cast :send_event, event #{inspect(event)}, #{inspect(state)}")

    response = Protocol.serialize(event)
    Logger.info("Response #{inspect(response)}")
    :gen_tcp.send(state.socket, response <> "\n")
    {:noreply, state}
  end

  # Catch all
  def handle_cast(message, state) do
    Logger.warning("Session unknown cast #{inspect(message)}")
    {:noreply, state}
  end

  defp handle_request(request, state) do
    case Protocol.deserialize(request) do
      {:error, error} ->
        {Protocol.serialize({:error, error}), state}

      event ->
        {result, state} = handle_event(event, state)
        Logger.info("BattleManager handle_request event: #{inspect(event)}, #{inspect(state)}")
        {Protocol.serialize(result), state}
    end
  end

  defp handle_event(:hello, state) do
    {:hi, state}
  end

  defp handle_event({:login, name}, state) do
    case UsersDatabase.find_by_name(name) do
      {:ok, user} ->
        Logger.info("Auth user #{inspect(user)}")

        SessionManager.register_user(user)

        state = %Session{state | user: user}
        {:ok, state}

      {:error, :not_found} ->
        Logger.warning("User #{name} auth error")
        {{:error, :invalid_auth}, state}
    end
  end

  defp handle_event(:play, state) do
    IO.puts("handle_event :play")

    case BattleManager.create_battle(state) do
      {:ok, battle_pid, :waiting_for_opponent} ->
        Logger.info("Session waiting for oppenent...")
        state = %Session{state | battle_pid: battle_pid}
        {:waiting_for_opponent, state}

      {:ok, battle_pid} ->
        Logger.info("Session start battle #{inspect(battle_pid)}")
        state = %Session{state | battle_pid: battle_pid}

        {:ok, current_move} = Battle.get_current_move(state.battle_pid)
        response_start = Protocol.serialize(:start_battle)
        response_rule = Protocol.serialize(:rule)
        response_move = Protocol.serialize(:move)
        :gen_tcp.send(current_move.socket, response_start <> "\n")
        :gen_tcp.send(current_move.socket, response_rule <> "\n")
        :gen_tcp.send(current_move.socket, response_move <> "\n")

        :gen_tcp.send(state.socket, response_start <> "\n")
        {:waiting_opponent_move, state}
    end
  end

  defp handle_event({:move, cell_number}, state) do
    Logger.info("Add move #{cell_number} to field #{inspect(Battle.get_field(state.battle_pid))}")

    case Battle.make_move(state.battle_pid, state.session_pid, String.to_integer(cell_number)) do
      :ok ->
        # NOTE : Дилема: слать сообщение через API Session нельзя.
        # GenServer не может обращаться к своему клиентскому API
        # Как быть?
        {:ok, opponent} = Battle.get_current_move(state.battle_pid)
        {:ok, field} = Battle.get_field(state.battle_pid)
        response_field = Protocol.serialize({:field, Field.draw_field(field)})
        response_move = Protocol.serialize(:move)
        resonse_lose = Protocol.serialize(:lose)

        case Field.check_who_win(field) do
          {:win, _sign} ->
            :gen_tcp.send(opponent.socket, resonse_lose)

            # TODO : Вместо сессии передать пользователя или anonimus
            Battle.finish_battle(state.battle_pid, :win, state)
            IO.inspect(Battle.get_state(state.battle_pid))

            :gen_tcp.send(opponent.socket, "\nResult:\n" <> response_field)

            {{:win, response_field}, state}

          :no_win ->
            :gen_tcp.send(opponent.socket, response_field <> "\n")
            :gen_tcp.send(opponent.socket, response_move <> "\n")

            {:ok, state}
        end

      {:error, :wrong_cell_number} ->
        {{:error, :wrong_cell_number}, state}

      {:error, :impossible_move} ->
        {{:error, :impossible_move}, state}

      {:error, :move_order_broken} ->
        {{:error, :move_order_broken}, state}
    end
  end

  defp on_client_disconnect(state) do
    SessionManager.unregister_user(state.user)
    # TODO: Remove user from Battle
    state
  end
end
