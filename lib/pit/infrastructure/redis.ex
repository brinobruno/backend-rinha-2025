defmodule Pit.Infrastructure.Redis do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    redis_url = System.get_env("REDIS_URL") || "redis://localhost:6379"

    children = [
      {Redix, {redis_url, name: :redix, socket_opts: [keepalive: true]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def command(command) do
    Redix.command(:redix, command)
  end

  def command(command, timeout) do
    Redix.command(:redix, command, timeout: timeout)
  end
end
