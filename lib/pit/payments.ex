defmodule Pit.Payments do
  require Logger

  alias Pit.Payments.Models.Payment
  alias Pit.Payments.Queue.Manager
  alias Pit.Repo

  import Ecto.Query

  def new_payment(%{"correlationId" => cid, "amount" => amount}) do
    Logger.info("🆕 New payment request: #{cid}, amount: #{amount}")

    case check_existing_payment(cid) do
      {:ok, _existing} ->
        Logger.info("🔄 Payment already exists: #{cid}, returning success")
        {:ok, "payment already processed"}

      {:error, :not_found} ->
        Logger.info("✅ New payment, queueing: #{cid}")

        payment = %{correlation_id: cid, amount: amount}
        Manager.new(payment)
        {:ok, "payment queued"}

      {:error, reason} ->
        Logger.error("❌ Error checking idempotency: #{cid}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def summary(params) do
    query = Payment
    |> select([p], {p.service_name, count(p.correlation_id), sum(p.amount)})
    |> maybe_filter_from(params["from"])
    |> maybe_filter_to(params["to"])
    |> group_by([p], p.service_name)

    result = Repo.all(query)

    fallback = Enum.find(result, fn tuple -> elem(tuple, 0) == "fallback" end)
    default = Enum.find(result, fn tuple -> elem(tuple, 0) == "default" end)

    %{
      fallback: %{
        "totalRequests" => if(not is_nil(fallback), do: elem(fallback, 1), else: 0),
        "totalAmount" =>
          if(not is_nil(fallback), do: Decimal.to_float(elem(fallback, 2)), else: 0.0)
      },
      default: %{
        "totalRequests" => if(not is_nil(default), do: elem(default, 1), else: 0),
        "totalAmount" =>
          if(not is_nil(default), do: Decimal.to_float(elem(default, 2)), else: 0.0)
      }
    }
  end

  defp check_existing_payment(correlation_id) do
    try do
      case Repo.get_by(Payment, correlation_id: correlation_id) do
        nil -> {:error, :not_found}
        payment -> {:ok, payment}
      end
    rescue
      e -> {:error, e}
    end
  end

  defp maybe_filter_from(query, nil), do: query

  defp maybe_filter_from(query, from) do
    case DateTime.from_iso8601(from) do
      {:ok, datetime, _} -> where(query, [p], p.inserted_at >= ^datetime)
      _ -> query
    end
  end

  defp maybe_filter_to(query, nil), do: query

  defp maybe_filter_to(query, to) do
    case DateTime.from_iso8601(to) do
      {:ok, datetime, _} -> where(query, [p], p.inserted_at <= ^datetime)
      _ -> query
    end
  end
end
