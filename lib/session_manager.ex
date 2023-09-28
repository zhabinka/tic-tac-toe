defmodule TicTacToe.SessionManager do
  require Logger
  use GenServer

  @sessions_registry_name :sessions_registry

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

  def register_user(user) do
    GenServer.call(__MODULE__, {:register, user})
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

    Registry.start_link(name: @sessions_registry_name, keys: :unique)

    1..state.pool_size
    |> Enum.each(fn session_id ->
      # session_id = UUID.uuid1()
      TicTacToe.SessionSup.start_acceptor(session_id, listening_socket)
    end)

    state = %State{state | listening_socket: listening_socket}
    Logger.info("SessionManager listen socket #{inspect(listening_socket)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:register, user}, _from, state) do
    Registry.register(@sessions_registry_name, user.id, user)
    {:reply, :ok, state}
  end

  # Catch all
  def handle_call(message, _from, state) do
    Logger.warning("SessionManager unknown call #{inspect(message)}")
    {:noreply, state}
  end
end
