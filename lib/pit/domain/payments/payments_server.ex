defmodule Pit.Domain.Payments.PaymentsServer do
  use GenServer

  require Logger

  alias Pit.Domain.Payments.Processor

  @health_check_interval_ms 5 * 1000

  # Client (Public API)
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # Server (GenServer Callbacks)
  @impl true
  def init(_state) do
    # Initialize status values in Redis for better performance
    set_status(:default, %{status: :down, min_response_time: 999999, last_check: 0})
    set_status(:fallback, %{status: :down, min_response_time: 999999, last_check: 0})

    Process.send_after(self(), :do_processor_health_check, 100)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:do_processor_health_check, state) do
    tasks = [
      Task.async(fn -> Processor.health_check(:default) end),
      Task.async(fn -> Processor.health_check(:fallback) end)
    ]

    results = case Task.await_many(tasks, 12000) do
      results when is_list(results) ->
        results
      {:exit, _reason} ->
        [{:error, "timeout"}, {:error, "timeout"}]
    end

    results
    |> Enum.with_index()
    |> Enum.each(fn {result, index} ->
      processor = if index == 0, do: :default, else: :fallback
      case result do
        {:ok, response} -> handle_processor_status(response, processor)
        {:error, _reason} ->
          set_status(processor, %{status: :down, min_response_time: 999999, last_check: System.system_time(:millisecond)})
      end
    end)

    # Reschedule
    Process.send_after(self(), :do_processor_health_check, @health_check_interval_ms)
    {:noreply, state}
  end

  defp handle_processor_status(check_response, :default) do
    case Jason.decode(check_response) do
      {:ok, %{"failing" => false, "minResponseTime" => min_response_time}} ->
        current_status = get_current_status(:default)
        new_status = %{status: :up, min_response_time: min_response_time, last_check: System.system_time(:millisecond)}

        if current_status != new_status do
          set_status(:default, new_status)
          Logger.info("default gateway is up ✅ (response time: #{min_response_time}ms)")
        end

      {:ok, %{"failing" => true, "minResponseTime" => min_response_time}} ->
        current_status = get_current_status(:default)
        new_status = %{status: :down, min_response_time: min_response_time, last_check: System.system_time(:millisecond)}

        if current_status != new_status do
          set_status(:default, new_status)
          Logger.info("default gateway is down ❌")
        end

      {:error, decode_error} ->
        Logger.error("error while health checking default ❌ #{inspect(decode_error)}")
    end
  end

  defp handle_processor_status(check_response, :fallback) do
    case Jason.decode(check_response) do
      {:ok, %{"failing" => false, "minResponseTime" => min_response_time}} ->
        current_status = get_current_status(:fallback)
        new_status = %{status: :up, min_response_time: min_response_time, last_check: System.system_time(:millisecond)}

        if current_status != new_status do
          set_status(:fallback, new_status)
          Logger.info("fallback gateway is up ✅ (response time: #{min_response_time}ms)")
        end

      {:ok, %{"failing" => true, "minResponseTime" => min_response_time}} ->
        current_status = get_current_status(:fallback)
        new_status = %{status: :down, min_response_time: min_response_time, last_check: System.system_time(:millisecond)}

        if current_status != new_status do
          set_status(:fallback, new_status)
          Logger.info("fallback gateway is down ❌")
        end

      {:error, decode_error} ->
        Logger.error("error while health checking fallback ❌ #{inspect(decode_error)}")
    end
  end

  defp get_current_status(key) do
    case get_status(key) do
      {:ok, status} -> status
      :error -> %{status: :down, min_response_time: 999999, last_check: 0}
    end
  end

  # Redis-based status management
  def get_status(key) do
    case Redix.command(:redix, ["GET", "processor_status:#{key}"]) do
      {:ok, nil} -> :error
      {:ok, status_json} ->
        case Jason.decode(status_json) do
          {:ok, status} -> {:ok, status}
          {:error, _} -> :error
        end
      {:error, _} -> :error
    end
  end

  def set_status(key, value) when is_atom(key) do
    status_json = Jason.encode!(value)
    Redix.command(:redix, ["SET", "processor_status:#{key}", status_json, "EX", "60"])
  end

  def select_best_processor do
    default_status = get_current_status(:default)
    fallback_status = get_current_status(:fallback)

    cond do
      healthy_and_fast?(default_status, 50) ->
        {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}

      healthy_and_fast?(fallback_status, 100) and not healthy_and_fast?(default_status, 200) ->
        {:ok, :fallback, System.get_env("PROCESSOR_FALLBACK_URL")}

      healthy_and_fast?(default_status, 200) ->
        {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}

      healthy_and_fast?(fallback_status, 300) and not healthy_and_fast?(default_status, 500) ->
        {:ok, :fallback, System.get_env("PROCESSOR_FALLBACK_URL")}

      healthy?(default_status) ->
        {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}

      healthy?(fallback_status) ->
        {:ok, :fallback, System.get_env("PROCESSOR_FALLBACK_URL")}

      # If both are down
      true ->
        {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}
    end
  end

  def select_processor_with_load_balancing do
    case Redix.command(:redix, ["INCR", "load_balancer_counter"]) do
      {:ok, counter} ->
        if rem(counter, 2) == 0 do
          {:ok, :fallback, System.get_env("PROCESSOR_FALLBACK_URL")}
        else
          {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}
        end
      _ ->
        {:ok, :default, System.get_env("PROCESSOR_DEFAULT_URL")}
    end
  end

  defp healthy_and_fast?(%{status: :up, min_response_time: mrt}, threshold) do
    mrt <= threshold
  end

  defp healthy_and_fast?(_status, _), do: false

  defp healthy?(%{status: :up, min_response_time: _mrt}), do: true
  defp healthy?(_status), do: false
end
