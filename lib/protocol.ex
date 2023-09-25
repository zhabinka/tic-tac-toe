defmodule TicTacToe.Protocol do
  require Logger

  def deserialize("hello"), do: :hello
  def deserialize("play"), do: :play

  # Catch all
  def deserialize(message) do
    Logger.warning("Protocol: unknown data #{message}")
    {:error, :unknown_message}
  end

  def serialize(:waiting_for_opponent), do: "Waiting for opponent"
  def serialize({:play, battle}), do: "The game has started, #{inspect(battle)}"
  def serialize(:ok), do: "OK"
  def serialize({:error, error}), do: "ERROR: #{inspect(error)}"
  def serialize(:hi), do: "Hi!"
end
