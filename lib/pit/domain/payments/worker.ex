defmodule Pit.Domain.Payments.Worker do
  use GenServer
  require Logger

  alias Pit.Domain.Payments.Create

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Start processing immediately
    Process.send_after(self(), :process_payments, 100)
    {:ok, state}
  end

  @impl true
  def handle_info(:process_payments, state) do
    # Process any pending payments
    Create.process_retry_queue()

    # Schedule next processing
    Process.send_after(self(), :process_payments, 500)  # Process every 500ms
    {:noreply, state}
  end
end
