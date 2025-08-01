defmodule Pit.Domain.Payments.RetryProcessor do
  use GenServer
  require Logger

  alias Pit.Domain.Payments.Create

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Start processing retry queue immediately
    Process.send_after(self(), :process_retry_queue, 100)
    {:ok, state}
  end

  @impl true
  def handle_info(:process_retry_queue, state) do
    # Process retry queue
    Create.process_retry_queue()

    # Schedule next processing
    Process.send_after(self(), :process_retry_queue, 1000)  # Process every second
    {:noreply, state}
  end
end
