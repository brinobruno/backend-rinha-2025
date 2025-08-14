defmodule Pit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        PitWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:pit, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Pit.PubSub},
        PitWeb.Endpoint,
        {Finch, name: Pit.Finch, pool_size: 2000},
        Pit.Repo,
        Pit.Payments.Monitoring.HealthTracker,
        Pit.Payments.Storage.BatchPersister,
        Pit.Payments.Supervision.WorkerSupervisor,
        {Pit.Payments.Queue.Manager, 8},
        Pit.Payments.Monitoring.HealthMonitor
      ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pit.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✅ Application started successfully")
        {:ok, pid}
      error ->
        Logger.error("❌ Failed to start application: #{inspect(error)}")
        error
    end
  end
end
