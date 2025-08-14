defmodule Pit.Payments.Supervision.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_workers(count) do
    Enum.each(1..count, fn _ ->
      DynamicSupervisor.start_child(__MODULE__, {Pit.Payments.Queue.Worker, nil})
    end)
  end
end
