defmodule PitWeb.PaymentController do
  use PitWeb, :controller

  alias Pit.Payments.Create
  alias Pit.Payments.Get

  def create(conn, _params) do
    body = conn.body_params

    case Create.call(body) do
      {:ok, response} ->
        json(conn, %{status: "success", data: response})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: reason})
    end
  end

  # TOOD ADD DATE FILTER
  def get(conn, _params) do
    case Get.call() do
      {:ok, response} ->
        json(conn, response)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: reason})
    end
  end
end
