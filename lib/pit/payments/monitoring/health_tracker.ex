defmodule Pit.Payments.Monitoring.HealthTracker do
  use GenServer
  @ets_table :payment_processor_health

  def start_link(opts \\ []) do
    @ets_table = :ets.new(@ets_table, [:set, :public, :named_table])

    :ets.insert(@ets_table, {:default, %{failing: false, min_response_time: 50}})
    :ets.insert(@ets_table, {:fallback, %{failing: false, min_response_time: 100}})
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{ets_ready: true}}
  end

  def update_status(service, %{failing: failing, min_response_time: min_response_time}) do
    :ets.insert(@ets_table, {service, %{failing: failing, min_response_time: min_response_time}})
  end

  def get_best_processor do
    default_status = :ets.lookup(@ets_table, :default) |> List.first() |> elem(1)
    fallback_status = :ets.lookup(@ets_table, :fallback) |> List.first() |> elem(1)

    require Logger

    cond do
      default_status.failing and not fallback_status.failing ->
        :fallback
      not fallback_status.failing and fallback_status.min_response_time <= 100 ->
        :fallback
      not default_status.failing and default_status.min_response_time <= 150 ->
        :default
      true ->
        :default
    end
  end

  def get_status(service) do
    case :ets.lookup(@ets_table, service) do
      [{^service, status}] -> status
      [] -> %{failing: true, min_response_time: 999999}
    end
  end
end
