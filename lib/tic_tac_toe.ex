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
    Logger.info("Start TicTacToeServer")
    {:ok, self()}
  end
end
