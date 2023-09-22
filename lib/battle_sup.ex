defmodule TicTacToe.BattleSup do
  require Logger
  use DynamicSupervisor

  @sup_name :battle_sup
  @registry_name :battle_registry

  def start_link(_) do
    Registry.start_link(keys: :unique, name: @registry_name)
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
  end

  def start_battle(battle_id) do
    process_name = {:via, Registry, {@registry_name, battle_id}}
    child_spec = {TicTacToe.Battle, {battle_id, process_name}}
    DynamicSupervisor.start_child(@sup_name, child_spec)
  end

  @impl true
  def init(_) do
    Logger.info("#{@sup_name} has started from #{inspect(self())}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
