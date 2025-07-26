defmodule Pit.Payments.PaymentsServer do
  use GenServer

  require Logger

  alias Pit.Payments.Processor

  @health_check_interval_ms 5 * 1000

  # Client (Public API)
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def call(:test_call) do
    GenServer.call(__MODULE__, :test_call)
  end

  # Server (GenServer Callbacks)
  @impl true
  def init(_state) do
    case :ets.whereis(:payment_server_table) do
      :undefined ->
        :ets.new(:payment_server_table, [:named_table, :public, :set])
        Logger.info("✅ ETS :payment_server_table created successfully")

      _ ->
        Logger.info("⚠️ ETS :payment_server_table already exists")
    end

    Logger.info("✅ Tokens initialized")

    # Schedule periodic expiration check
    Process.send_after(self(), :do_processor_health_check, @health_check_interval_ms)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:do_processor_health_check, state) do
    case Processor.health_check() do
      {:ok, check_response} ->
        case Jason.decode(check_response) do
          {:ok, %{"failing" => false}} ->
            set_status(:up)
            Logger.info("default gateway is up ✅")

          {:ok, %{"failing" => true}} ->
            set_status(:down)
            Logger.info("default gateway is down ❌")

          {:error, decode_error} ->
            Logger.error("error while health checking ❌ #{inspect(decode_error)}")
        end

      {:error, reason} ->
        Logger.error("error ❌ #{inspect(reason)}")
    end

    # Reschedule the check
    Process.send_after(self(), :do_processor_health_check, @health_check_interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_call(:test_call, _from, state) do
    IO.inspect(state)
    {:reply, state, state}
  end

  def get_status() do
    case :ets.lookup(:payment_server_table, :status) do
      [{:status, value}] -> {:ok, value}
      [] -> :error
    end
  end

  def set_status(value) do
    :ets.insert(:payment_server_table, {:status, value})
  end
end
