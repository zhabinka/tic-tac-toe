defmodule TicTacToe.Sessions do
  require Logger

  defmodule Session do
    use GenServer

    defmodule State do
      defstruct [
        :session_id,
        :listening_socket,
        :socket,
        :user
      ]
    end

    def start_link({session_id, listening_socket}) do
      GenServer.start_link(__MODULE__, {session_id, listening_socket})
    end

    @impl true
    def init({session_id, listening_socket}) do
      # battle = TicTacToe.Game.BattleManager.start_battle(session_id)
      state = %State{
        session_id: session_id,
        listening_socket: listening_socket
      }

      Logger.info("Session #{session_id} has started, state #{inspect(state)}")
      {:ok, state, {:continue, :waiting_for_client}}
    end

    @impl true
    def handle_continue(:waiting_for_client, state) do
      Logger.info("Session #{state.session_id} is waiting for client")
      {:ok, socket} = :gen_tcp.accept(state.listening_socket)
      state = %State{state | socket: socket}
      Logger.info("Session #{state.session_id} got client with #{inspect(state)}")
      {:noreply, state, {:continue, :receive_data}}
    end

    def handle_continue(:receive_data, state) do
      case :gen_tcp.recv(state.socket, 0, 30_000) do
        {:ok, data} ->
          Logger.info("Session #{state.session_id} got data #{data}")

          response =
            data
            |> String.trim_trailing()
            |> handle_request()

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

    def handle_request(request) do
      alias TicTacToe.Protocol

      case Protocol.deserialize(request) do
        {:error, error} ->
          Protocol.serialize({:error, error})

        event ->
          Logger.info("Event: #{inspect(event)}")
          Protocol.serialize(:ok)
      end
    end
  end

  defmodule SessionManager do
    use GenServer

    defmodule State do
      defstruct [
        :port,
        :pool_size,
        :listening_socket
      ]
    end

    def start_link({port, pool_size}) do
      GenServer.start_link(__MODULE__, {port, pool_size})
    end

    @impl true
    def init({port, pool_size}) do
      state = %State{port: port, pool_size: pool_size}
      Logger.info("SessionManager has started with #{inspect(state)}")
      {:ok, state, {:continue, :delayed_init}}
    end

    @impl true
    def handle_continue(:delayed_init, state) do
      options = [
        :binary,
        {:active, false},
        {:packet, :line},
        {:reuseaddr, true}
      ]

      {:ok, listening_socket} = :gen_tcp.listen(state.port, options)

      1..state.pool_size
      |> Enum.each(fn session_id ->
        TicTacToe.Sessions.SessionSup.start_acceptor(session_id, listening_socket)
      end)

      state = %State{state | listening_socket: listening_socket}
      Logger.info("SessionManager listen socket #{inspect(listening_socket)}")
      {:noreply, state}
    end
  end

  defmodule SessionSup do
    use DynamicSupervisor

    @session_sup_name :session_sup

    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, :no_args, name: @session_sup_name)
    end

    def start_acceptor(session_id, listening_socket) do
      child_spec = {Session, {session_id, listening_socket}}
      DynamicSupervisor.start_child(@session_sup_name, child_spec)
    end

    @impl true
    def init(:no_args) do
      Logger.info("SessionSup has started")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end
end
