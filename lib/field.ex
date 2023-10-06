defmodule TicTacToe.Field do
  @type game_result :: {:win, :cross} | {:win, :zero} | :no_win

  alias TicTacToe.Model

  @spec check_who_win(Model.battle_field()) :: game_result
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

  @spec add_move_to_field(Model.battle_field(), number(), Model.sign()) ::
          {:ok, Model.battle_field()}
  def add_move_to_field(field, cell_number, sign) do
    if cell_number > 9 or cell_number < 1 do
      {:error, :wrong_cell_number}
    else
      row_index = div(cell_number - 1, 3)
      cell_index = rem(cell_number - 1, 3)
      row = elem(field, row_index)
      cell = elem(row, cell_index)

      cond do
        cell != :f ->
          {:error, :impossible_move}

        true ->
          {
            :ok,
            put_elem(field, row_index, put_elem(row, cell_index, sign))
          }
      end
    end
  end

  @spec draw_field(Model.battle_field()) :: String.t()
  def draw_field(field) do
    signs = %{cross: " x ", zero: " o ", f: "   "}
    {{a, b, c}, {d, e, f}, {g, h, i}} = field

    """
    #{Map.get(signs, a)}|#{Map.get(signs, b)}|#{Map.get(signs, c)}
    #{Map.get(signs, d)}|#{Map.get(signs, e)}|#{Map.get(signs, f)}
    #{Map.get(signs, g)}|#{Map.get(signs, h)}|#{Map.get(signs, i)}
    """
  end
end
