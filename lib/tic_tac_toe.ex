defmodule TicTacToe do
  @moduledoc """
  sup tree:
  - RootSup
    - PlayersMatcher
    - GamesSup
      - Game 1
      - Game 2
      - ...
  """
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
        {TicTacToe.Game.BattleSup, :no_args},
        {TicTacToe.Game.BattleManager, :no_args},
        {TicTacToe.Sessions.SessionManager, {port, pool_size}}
      ]

      Logger.info("RootSup start")
      Supervisor.init(child_spec, strategy: :rest_for_one)
    end
  end
end
