defmodule Pit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        PitWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:pit, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Pit.PubSub},
        # Start to serve requests, typically the last entry
        PitWeb.Endpoint,
        {Finch, name: MyFinch, pool_size: 2000},  # Significantly increased for better performance under load
        Pit.Infrastructure.Redis  # Updated path
      ] ++ payments_server_child(Mix.env())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp payments_server_child(:test), do: []
  defp payments_server_child(_env), do: [
    {Pit.Domain.Payments.PaymentsServer, []},  # Updated path
    {Pit.Domain.Payments.RetryProcessor, []},  # Updated path
    {Pit.Domain.Payments.Worker, []}  # Updated path
  ]

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(_changed, _new, _removed) do
    # Removed the call to PitWeb.Endpoint.config_change/2 as it doesn't exist
    :ok
  end
end
