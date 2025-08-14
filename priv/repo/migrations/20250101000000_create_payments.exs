defmodule Pit.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :correlation_id, :binary_id, primary_key: true
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :service_name, :string, null: false
      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:payments, [:correlation_id])
    create index(:payments, [:service_name])
    create index(:payments, [:inserted_at])
  end
end
