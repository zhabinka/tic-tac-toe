defmodule TicTacToe.Session do
  require Logger
  use GenServer

  alias TicTacToe.Model.{Session}

  def start_link({session_id, listening_socket}) do
    GenServer.start_link(__MODULE__, {session_id, listening_socket})
  end

  @impl true
  def init({session_id, listening_socket}) do
    state = %Session{
      session_id: session_id,
      listening_socket: listening_socket,
      socket: nil,
      user: nil,
      battle_pid: nil,
      has_opponent: false
    }

    Logger.info("Session #{session_id} has started, state #{inspect(state)}")
    {:ok, state, {:continue, :waiting_for_client}}
  end

  @impl true
  def handle_continue(:waiting_for_client, state) do
    Logger.info("Session #{state.session_id} is waiting for client")
    {:ok, socket} = :gen_tcp.accept(state.listening_socket)
    state = %Session{state | socket: socket}
    Logger.info("Session #{state.session_id} got client with #{inspect(state)}")
    {:noreply, state, {:continue, :receive_data}}
  end

  def handle_continue(:receive_data, state) do
    case :gen_tcp.recv(state.socket, 0, 30_000) do
      {:ok, data} ->
        Logger.info("Session #{state.session_id} got data #{data}")

        {response, state} =
          data
          |> String.trim_trailing()
          |> handle_request(state)

        :gen_tcp.send(state.socket, response <> "\n")
        {:noreply, state, {:continue, :receive_data}}

      {:error, :timeout} ->
        Logger.info("Session #{state.session_id} timeout")
        {:noreply, state, {:continue, :receive_data}}

      {:error, error} ->
        Logger.warning("Session #{state.session_id} has got error #{inspect(error)}")
        :gen_tcp.close(state.socket)
        {:noreply, state, {:continue, :waiting_for_client}}
    end
  end

  def handle_request(request, state) do
    alias TicTacToe.Protocol

    case Protocol.deserialize(request) do
      {:error, error} ->
        {Protocol.serialize({:error, error}), state}

      event ->
        {result, state} = handle_event(event, state)
        Logger.info("Event: #{inspect(event)}, #{inspect(state)}")
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
        state = %Session{state | user: user}
        {:ok, state}

      {:error, :not_found} ->
        Logger.warning("User #{name} auth error")
        {{:error, :invalid_auth}, state}
    end
  end

  def handle_event(:play, state) do
    IO.puts("handle_event :play")

    case TicTacToe.BattleManager.create_battle(state.session_id) do
      {:ok, :waiting_for_opponent} ->
        Logger.info("Session waiting for oppenent...")
        {:waiting_for_opponent, state}

      {:ok, battle_pid} ->
        Logger.info("Session start battle #{inspect(battle_pid)}!")
        {:play, state}
    end
  end
end
