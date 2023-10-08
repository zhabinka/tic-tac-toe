defmodule TicTacToe.Protocol do
  require Logger

  def deserialize("hello"), do: :hello
  def deserialize("login " <> name), do: {:login, name}
  def deserialize("play"), do: :play
  def deserialize("move " <> move), do: {:move, move}

  # Catch all
  def deserialize(message) do
    Logger.warning("Protocol: unknown data #{message}")
    {:error, :unknown_message}
  end

  def serialize(:waiting_for_opponent), do: "Waiting for opponent..."
  def serialize(:start_battle), do: "Battle has started!"

  def serialize(:rule) do
    field = " 1 | 2 | 3 \n 4 | 5 | 6 \n 7 | 8 | 9"
    "Battlefield:\n#{field}\nTo make move type 'move <cell number>'"
  end

  def serialize(:move), do: "Your move:"
  def serialize(:waiting_opponent_move), do: "Wait opponent move"
  def serialize(:win), do: "You have won. Congratulation!"
  def serialize(:lose), do: "You have lost. Don't be upset!"
  def serialize(:draw), do: "The battle ended in a draw"
  def serialize({:field, field}), do: field
  def serialize(:ok), do: "OK"
  def serialize({:error, error}), do: "ERROR: #{inspect(error)}"
  def serialize(:hi), do: "Hi!"
end
