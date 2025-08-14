defmodule Pit.Payments.Storage.BatchPersister do
  use GenServer

  require Logger

  alias Pit.Payments.Models.Payment
  alias Pit.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :persist, 35)
    {:ok, []}
  end

  def handle_info(:persist, []) do
    Process.send_after(self(), :persist, 35)
    {:noreply, []}
  end

  def handle_info(:persist, payments) do
    Process.send_after(self(), :persist, 35)
    insert_payments(payments)
    {:noreply, []}
  end

  def handle_cast({:new, payment}, state) do
    {:noreply, [payment | state]}
  end

  defp insert_payments(payments) do
    formatted_payments = Enum.map(payments, fn payment ->
      %{
        correlation_id: payment.correlation_id,
        amount: payment.amount,
        service_name: payment.service_name,
        inserted_at: payment.inserted_at
      }
    end)

    try do
      Repo.transaction(fn ->
        case Repo.insert_all(Payment, formatted_payments, on_conflict: :nothing) do
          {count, _} when count > 0 ->
            Logger.info("✅ Successfully persisted #{count}/#{length(payments)} payments to database")
          {0, _} ->
            Logger.warning("⚠️ No payments persisted")
          error ->
            Logger.error("❌ Error in batch insert: #{inspect(error)}")
            Repo.rollback(error)
        end
      end)
    rescue
      e ->
        Logger.error("❌ [rescue]: #{inspect(e)}, trying individual inserts")
        Enum.each(formatted_payments, fn payment ->
          try do
            case Repo.insert(Payment, payment) do
              {:ok, _} ->
                Logger.info("✅ Individual payment persisted: #{payment.correlation_id}")
              {:error, changeset} ->
                Logger.error("❌ Individual payment failed: #{payment.correlation_id}, errors: #{inspect(changeset.errors)}")
            end
          rescue
            e -> Logger.error("❌ Individual payment insert crashed: #{payment.correlation_id}, error: #{inspect(e)}")
          end
        end)
    end
  end
end
