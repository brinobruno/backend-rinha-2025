defmodule Pit.Payments.Create do
  alias Pit.Repo
  alias Pit.Payments.Payment
  alias Pit.Payments.PaymentsServer

  def call(payment_body) do
    handle_response(payment_body)
  end

  defp handle_response(payment_body) do
    case PaymentsServer.get_status() do
      {:ok, :up} ->
        send_payment_default(payment_body)

      {:ok, :down} ->
        send_payment_fallback(payment_body)

      :error ->
        send_payment_fallback(payment_body)
    end
  end

  defp send_payment_default(body) do
    url = System.get_env("PROCESSOR_DEFAULT_URL")

    updated_body = Map.put(body, "requestedAt", DateTime.utc_now() |> DateTime.to_iso8601())

    response =
      Finch.build(
        :post,
        "#{url}/payments",
        [
          {"content-type", "application/json"}
        ],
        Jason.encode!(updated_body)
      )
      |> Finch.request(MyFinch)

    handle_build_params(body, :default)
    |> handle_insert()

    handle_feedback(response)
  end

  defp send_payment_fallback(body) do
    url = System.get_env("PROCESSOR_FALLBACK_URL")

    updated_body = Map.put(body, "requestedAt", DateTime.utc_now() |> DateTime.to_iso8601())

    response =
      Finch.build(
        :post,
        "#{url}/payments",
        [
          {"content-type", "application/json"}
        ],
        Jason.encode!(updated_body)
      )
      |> Finch.request(MyFinch)

    handle_build_params(body, :fallback)
    |> handle_insert()

    handle_feedback(response)
  end

  defp handle_feedback({:ok, %Finch.Response{status: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, _decoded} -> {:ok, "ALL GOOD!!"}
      {:error, _err} -> {:error, "ALL BAD!"}
    end
  end

  defp handle_feedback({:ok, %Finch.Response{status: status, body: _body}}) do
    {:error, "Unexpected status: #{status}"}
  end

  defp handle_feedback({:error, reason}) do
    {:error, reason}
  end

  defp handle_build_params(params, :default) do
    %{
      "correlation_id" => params["correlationId"],
      "amount" => params["amount"],
      "processor" => "default"
    }
  end

  defp handle_build_params(params, :fallback) do
    %{
      "correlation_id" => params["correlationId"],
      "amount" => params["amount"],
      "processor" => "fallback"
    }
  end

  defp handle_insert(params) do
    changeset = Payment.changeset(%Payment{}, params)

    case Repo.insert(changeset) do
      {:ok, user} -> IO.inspect(user, label: "Inserted payment")
      {:error, changeset} -> IO.inspect(changeset.errors, label: "Validation Errors")
    end
  end
end
