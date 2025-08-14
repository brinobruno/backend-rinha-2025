defmodule Pit.Payments.Queue.Manager do
  use GenServer
  require Logger
  alias Pit.Payments.Monitoring.HealthTracker

  def start_link(workers_count), do: GenServer.start_link(__MODULE__, workers_count, name: __MODULE__)

  def init(workers_count) do
    Process.send_after(self(), :create_workers, 100)
    {:ok, {workers_count, :queue.new()}}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def get_payment do
    GenServer.call(__MODULE__, :get)
  end

  def handle_info(:create_workers, {workers_count, payments}) do
    try_create_workers(workers_count)
    {:noreply, {workers_count, payments}}
  end

  def handle_call(:get, _, {workers_count, payments}) do
    case :queue.out_r(payments) do
      {:empty, _} ->
        {:reply, :none, {workers_count, payments}}
      {{:value, payment}, remaining_payments} ->
        processor = HealthTracker.get_best_processor()
        {:reply, {payment, processor}, {workers_count, remaining_payments}}
    end
  end

  def handle_cast({:new, payment}, {workers_count, payments}) do
    new_payments = :queue.in(payment, payments)
    {:noreply, {workers_count, new_payments}}
  end

  defp try_create_workers(workers_count) do
    try do
      Pit.Payments.Supervision.WorkerSupervisor.start_workers(workers_count)
      Logger.info("✅ Successfully created #{workers_count} workers")
    rescue
      e ->
        Logger.error("❌ Failed to create workers: #{inspect(e)}")
        Process.send_after(self(), :create_workers, 1000)
    end
  end
end
