defmodule Pit.Domain.Payments.Get do
  require Logger

  def call(params) do
    from_iso = params["from"]
    to_iso = params["to"]

    result = get_redis_summary(from_iso, to_iso)
    {:ok, result}
  end

  defp get_redis_summary(from_iso, to_iso) do
    default_requests = get_redis_value("payments:summary:default:total_requests", "0")
    default_amount_cents = get_redis_value("payments:summary:default:total_amount_cents", "0")

    fallback_requests = get_redis_value("payments:summary:fallback:total_requests", "0")
    fallback_amount_cents = get_redis_value("payments:summary:fallback:total_amount_cents", "0")

    case {from_iso, to_iso} do
      {nil, nil} ->
        %{
          default: %{
            totalRequests: safe_string_to_integer(default_requests),
            totalAmount: cents_to_float(default_amount_cents)
          },
          fallback: %{
            totalRequests: safe_string_to_integer(fallback_requests),
            totalAmount: cents_to_float(fallback_amount_cents)
          }
        }
      _ ->
        %{
          default: %{
            totalRequests: safe_string_to_integer(default_requests),
            totalAmount: cents_to_float(default_amount_cents)
          },
          fallback: %{
            totalRequests: safe_string_to_integer(fallback_requests),
            totalAmount: cents_to_float(fallback_amount_cents)
          }
        }
    end
  end

  defp get_redis_value(key, default) do
    case Redix.command(:redix, ["GET", key]) do
      {:ok, value} when is_binary(value) -> value
      _ -> default
    end
  end

  defp safe_string_to_integer(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp cents_to_float(cents_str) do
    case Integer.parse(cents_str) do
      {cents, _} -> cents / 100.0
      :error -> 0.0
    end
  end
end
