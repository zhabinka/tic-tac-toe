defmodule TicTacToe.Session do
  require Logger
  use GenServer

  alias TicTacToe.Model.{Session}

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

  def handle_info(msg, state) do
    Logger.error("Session #{inspect(self())} unknown info #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_request(request, state) do
    alias TicTacToe.Protocol

    case Protocol.deserialize(request) do
      {:error, error} ->
        {Protocol.serialize({:error, error}), state}

      event ->
        {result, state} = handle_event(event, state)
        Logger.info("BattleManager handle_request event: #{inspect(event)}, #{inspect(state)}")
        {Protocol.serialize(result), state}
    end
  end

  def handle_event(:hello, state) do
    {:hi, state}
  end

  def handle_event({:login, name}, state) do
    case TicTacToe.UsersDatabase.find_by_name(name) do
      {:ok, user} ->
        Logger.info("Auth user #{inspect(user)}")

        TicTacToe.SessionManager.register_user(user)

        state = %Session{state | user: user}
        {:ok, state}

      {:error, :not_found} ->
        Logger.warning("User #{name} auth error")
        {{:error, :invalid_auth}, state}
    end
  end

  def handle_event(:play, state) do
    IO.puts("handle_event :play")

    case TicTacToe.BattleManager.create_battle(state) do
      {:ok, :waiting_for_opponent} ->
        Logger.info("Session waiting for oppenent...")
        {:waiting_for_opponent, state}

      {:ok, battle_pid} ->
        Logger.info("Session start battle #{inspect(battle_pid)}")
        TicTacToe.Battle.broadcast(battle_pid, :broadcast)
        {:play, state}
    end
  end

  @impl true
  def handle_cast({:send_event, event}, state) do
    Logger.info("Session cast :send_event, event #{inspect(event)}, #{inspect(state)}")

    response = TicTacToe.Protocol.serialize(event)
    Logger.info("Response #{inspect(response)}")
    :gen_tcp.send(state.socket, response <> "\n")
    {:noreply, state}
  end

  # Catch all
  def handle_cast(message, state) do
    Logger.warning("Session unknown cast #{inspect(message)}")
    {:noreply, state}
  end

  defp on_client_disconnect(state) do
    Registry.unregister(:sessions_registry, state.user.id)
    # TODO: Remove user from Battle
    state
  end
end
