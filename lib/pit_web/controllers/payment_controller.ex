defmodule PitWeb.PaymentController do
  use PitWeb, :controller

  alias Pit.Domain.Payments.Get
  alias Pit.Domain.Payments.Create

  def create(conn, _params) do
    body = conn.body_params

    # Validate required fields
    case validate_payment_body(body) do
      :ok ->
        # Use fast processing with Redis caching
        case Create.process_payment_fast(body) do
          {:ok, _message} ->
            conn |> put_status(202) |> json(%{status: "accepted"})
          {:error, "no healthy processor"} ->
            # Return 503 when no healthy processor is available
            conn |> put_status(:service_unavailable) |> json(%{status: "error", message: "no healthy processor"})
          {:error, _reason} ->
            # Return 500 for other errors
            conn |> put_status(:internal_server_error) |> json(%{status: "error"})
        end
      {:error, reason} ->
        conn |> put_status(:bad_request) |> json(%{status: "error", message: reason})
    end
  end

  def get(conn, params) do
    case Get.call(params) do
      {:ok, response} ->
        json(conn, response)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: reason})
    end
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
