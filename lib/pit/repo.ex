defmodule Pit.Repo do
  use Ecto.Repo,
    otp_app: :pit,
    adapter: Ecto.Adapters.Postgres
end
