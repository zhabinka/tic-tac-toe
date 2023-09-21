defmodule TicTacToeServer do
  @moduledoc """
  sup tree:
  - RootSup
    - PlayersMatcher
    - GamesSup
      - Game 1
      - Game 2
      - ...
  """
  require Logger

  def start() do
    IO.puts("TicTacToeServer.RootSup.start_link")
    TicTacToeServer.RootSup.start_link(:no_args)
  end

  defmodule RootSup do
    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, :no_args)
    end

    @impl true
    def init(_) do
      options = %{
        port: 3000
      }

      child_spec = [
        {TicTacToeServer.GamesSup, :no_args},
        {TicTacToeServer.PlayersMatcher, options}
      ]

      # Может, нужна :rest_for_one
      Supervisor.init(child_spec, strategy: :one_for_one)
    end
  end

  defmodule PlayersMatcher do
    use GenServer

    def start_link(options) do
      GenServer.start_link(__MODULE__, options)
    end

    @impl true
    def init(settings) do
      port = Map.get(settings, :port, 1234)
      pool_size = Map.get(settings, :pool_size, 5)

      options = [
        :binary,
        {:active, true},
        {:reuseaddr, true}
      ]

      {:ok, listening_socket} = :gen_tcp.listen(port, options)
      state = Map.put(settings, :listening_socket, listening_socket)
      IO.puts("Start PlayersMatcher with state #{inspect(state)}")

      1..pool_size
      |> Enum.each(fn id -> TicTacToeServer.GamesSup.prepare_game(id, listening_socket) end)

      {:ok, state}
    end
  end

  defmodule GamesSup do
    use DynamicSupervisor

    @name :games_sup
    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
    end

    def prepare_game(id, listening_socket) do
      child_spec = {TicTacToeServer.Game, {id, listening_socket}}
      DynamicSupervisor.start_child(@name, child_spec)
    end

    @impl true
    def init(_) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end

  defmodule Game do
    use GenServer

    def start_link({id, listening_socket}) do
      GenServer.start_link(__MODULE__, {id, listening_socket})
    end

    @impl true
    def init({id, listening_socket}) do
      state = %{
        id: id,
        listening_socket: listening_socket,
        has_opponent: false
      }

      IO.puts("Prepare Game #{id} with: has_opponent #{inspect(state.has_opponent)}")
      {:ok, state, {:continue, :waiting_for_players}}
    end

    @impl true
    def handle_continue(:waiting_for_players, state) do
      IO.puts("Game #{state.id} is waiting for players, #{inspect(state)}")
      {:ok, socket} = :gen_tcp.accept(state.listening_socket)
      IO.puts("Game #{state.id} got first player on #{inspect(socket)}, #{inspect(state)}")

      cond do
        state.has_opponent ->
          new_state = %{state | has_opponent: false}
          {:noreply, new_state, {:continue, :run_game}}

        true ->
          new_state = %{state | has_opponent: true}
          {:noreply, new_state, {:continue, :waiting_for_players}}
      end
    end

    def handle_continue(:waiting_for_players, state) do
      IO.puts("Game #{state.id} is waiting for players, #{inspect(state)}")
      {:ok, socket} = :gen_tcp.accept(state.listening_socket)
      IO.puts("Game #{state.id} got first player on #{inspect(socket)}, #{inspect(state)}")

      cond do
        state.has_opponent ->
          new_state = %{state | has_opponent: false}
          {:noreply, new_state, {:continue, :run_game}}

        true ->
          new_state = %{state | has_opponent: true}
          {:noreply, new_state, {:continue, :waiting_for_players}}
      end
    end

    def handle_continue(:run_game, state) do
      IO.puts("Game started!")
      {:noreply, state}
    end

    def handle_continue(message, state) do
      Logger.warning("Game got unknown message #{inspect(message)}")
      {:noreply, state}
    end
  end
end
