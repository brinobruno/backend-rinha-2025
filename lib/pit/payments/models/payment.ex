defmodule Pit.Payments.Models.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:correlation_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "payments" do
    field :amount, :decimal
    field :service_name, :string
    field :inserted_at, :utc_datetime_usec
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:correlation_id, :amount, :service_name, :inserted_at])
    |> validate_required([:correlation_id, :amount, :service_name, :inserted_at])
    |> unique_constraint(:correlation_id)
  end
end
