defmodule Pit.Payments.Monitoring.HealthMonitor do
  use GenServer

  alias Pit.Payments.External.ProcessorClient

  alias Pit.Payments.Monitoring.HealthTracker

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    reschedule()
    {:ok, %{}}
  end

  def reschedule do
    interval = 5000
    Process.send_after(self(), :check, interval)
  end

  def handle_info(:check, state) do
    reschedule()
          case ProcessorClient.get_processors_status() do
        {:ok, new_status} ->
          Enum.each(new_status, fn {service, status} ->
            HealthTracker.update_status(service, status)
          end)
          {:noreply, new_status}
        {:error, _error} ->
          {:noreply, state}
    end
  end
end
