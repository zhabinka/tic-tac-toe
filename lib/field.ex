defmodule TicTacToe.Field do
  @type game_result :: {:win, :cross} | {:win, :zero} | :no_win

  @spec check_who_win(TicTacToe.Model.battle_field()) :: game_result
  def check_who_win(field) do
    case field do
      {{a, a, a}, {_, _, _}, {_, _, _}} when a != :f -> {:win, a}
      {{_, _, _}, {a, a, a}, {_, _, _}} when a != :f -> {:win, a}
      {{_, _, _}, {_, _, _}, {a, a, a}} when a != :f -> {:win, a}
      {{a, _, _}, {a, _, _}, {a, _, _}} when a != :f -> {:win, a}
      {{_, a, _}, {_, a, _}, {_, a, _}} when a != :f -> {:win, a}
      {{_, _, a}, {_, _, a}, {_, _, a}} when a != :f -> {:win, a}
      {{a, _, _}, {_, a, _}, {_, _, a}} when a != :f -> {:win, a}
      {{_, _, a}, {_, a, _}, {a, _, _}} when a != :f -> {:win, a}
      _ -> :no_win
    end
  end
end
