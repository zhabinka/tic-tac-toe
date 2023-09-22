defmodule TicTacToe do
  use Application
  require Logger

  def start(_start_type, _args) do
    Logger.info("Start TicTacToe")
    TicTacToe.RootSup.start_link(:no_args)
  end

  defmodule RootSup do
    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, :no_args)
    end

    @impl true
    def init(_) do
      port = 3000
      pool_size = 5

      child_spec = [
        {TicTacToe.BattleSup, :no_args},
        {TicTacToe.BattleManager, :no_args},
        {TicTacToe.SessionSup, :no_args},
        {TicTacToe.SessionManager, {port, pool_size}}
      ]

      Logger.info("RootSup start")
      Supervisor.init(child_spec, strategy: :rest_for_one)
    end
  end
end
