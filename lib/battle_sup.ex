defmodule TicTacToe.BattleSup do
  require Logger
  use DynamicSupervisor

  @sup_name :battle_sup
  # @registry_name :battle_registry

  def start_link(_) do
    # Registry.start_link(keys: :unique, name: @registry_name)
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
  end

  def start_battle() do
    # process_name = {:via, Registry, {@registry_name, battle_id}}
    child_spec = {TicTacToe.Battle, :no_args}
    DynamicSupervisor.start_child(@sup_name, child_spec)
  end

  # NOTE: Как сделать общее имя хранилища для разных модулей?
  # def find_battle(battle_id) do
  #   case Registry.lookup(:battle_registry, battle_id) do
  #     [{pid, _}] -> {:ok, pid}
  #     [] -> {:error, :not_found}
  #   end
  # end

  @impl true
  def init(_) do
    Logger.info("#{@sup_name} has started from #{inspect(self())}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
