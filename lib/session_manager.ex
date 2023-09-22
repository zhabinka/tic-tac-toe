defmodule TicTacToe.SessionManager do
  require Logger
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
      TicTacToe.SessionSup.start_acceptor(session_id, listening_socket)
    end)

    state = %State{state | listening_socket: listening_socket}
    Logger.info("SessionManager listen socket #{inspect(listening_socket)}")
    {:noreply, state}
  end
end
