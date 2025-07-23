defmodule Pit.Payments.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    field :correlation_id, Ecto.UUID
    field :amount, :decimal
    field :processor, :string

    timestamps()
  end

  def changeset(payment, params \\ %{}) do
    payment
    |> cast(params, [:correlation_id, :amount, :processor])
    |> validate_required([:correlation_id, :amount, :processor])
    |> unique_constraint(:correlation_id)
    |> validate_processor(:processor)
  end

  def validate_processor(changeset, field) do
    validate_inclusion(changeset, field, ["default", "fallback"])
  end
end
