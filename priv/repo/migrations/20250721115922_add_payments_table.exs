defmodule Pit.Repo.Migrations.AddPaymentsTable do
  use Ecto.Migration

  def change do
    create table("payments") do
      add :correlation_id, :uuid, null: false
      add :amount, :decimal, null: false
      add :processor, :string, null: false

      timestamps()
    end
  end
end
