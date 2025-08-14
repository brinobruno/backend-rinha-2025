defmodule Pit.Payments.Queue.Worker do
  use GenServer
  require Logger
  alias Pit.Payments.External.ProcessorClient
  alias Pit.Payments.Storage.BatchPersister
  alias Pit.Payments.Queue.Manager

  @max_retries 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    Process.send_after(self(), :process, 0)
    {:ok, nil}
  end

  def handle_info(:process, state) do
          case Manager.get_payment() do
        :none ->
          Process.send_after(self(), :process, 20)
      {payment, service} ->
        payment_with_date_and_service =
          DateTime.utc_now()
          |> then(&Map.put(payment, :inserted_at, &1))
          |> Map.put(:service_name, to_string(service))

        case ProcessorClient.process_payment(service, payment_with_date_and_service) do
          {:ok, _amount} ->
            GenServer.cast(BatchPersister, {:new, payment_with_date_and_service})
            Process.send_after(self(), :process, 0)
          {:error, _reason} ->
            retry_count = Map.get(payment, :retry_count, 0)
            if retry_count < @max_retries do
              payment_with_retry = Map.put(payment, :retry_count, retry_count + 1)
              GenServer.cast(Manager, {:new, payment_with_retry})
            else
              # Max retries reached
              :ok
            end
            Process.send_after(self(), :process, 100)
        end
    end
    {:noreply, state}
  end
end
