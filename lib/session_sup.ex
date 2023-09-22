defmodule TicTacToe.SessionSup do
  require Logger
  use DynamicSupervisor

  @session_sup_name :session_sup

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @session_sup_name)
  end

  def start_acceptor(session_id, listening_socket) do
    child_spec = {TicTacToe.Session, {session_id, listening_socket}}
    DynamicSupervisor.start_child(@session_sup_name, child_spec)
  end

  @impl true
  def init(:no_args) do
    Logger.info("SessionSup has started")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
