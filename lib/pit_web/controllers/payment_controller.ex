defmodule PitWeb.PaymentController do
  use PitWeb, :controller

  alias Pit.Payments

  def create(conn, _params) do
    body = conn.body_params

    case validate_payment_body(body) do
      :ok ->
        case Payments.new_payment(body) do
          {:ok, _message} ->
            conn |> put_status(202) |> json(%{status: "accepted"})
          {:error, reason} ->
            conn |> put_status(:internal_server_error) |> json(%{status: "error", message: reason})
        end
      {:error, reason} ->
        conn |> put_status(:bad_request) |> json(%{status: "error", message: reason})
    end
  end

  def get(conn, params) do
    response = Payments.summary(params)
    json(conn, response)
  end

  def health(conn, _params) do
    conn |> json(%{status: "ok", timestamp: DateTime.utc_now()})
  end

  defp validate_payment_body(body) do
    cond do
      not is_map(body) ->
        {:error, "invalid request body"}
      not Map.has_key?(body, "correlationId") ->
        {:error, "correlationId is required"}
      not Map.has_key?(body, "amount") ->
        {:error, "amount is required"}
      not is_number(body["amount"]) ->
        {:error, "amount must be a number"}
      body["amount"] <= 0 ->
        {:error, "amount must be positive"}
      true ->
        :ok
    end
  end
end
