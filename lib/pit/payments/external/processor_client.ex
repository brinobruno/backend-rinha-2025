defmodule Pit.Payments.External.ProcessorClient do
  @timeout 1800
  @success_range 200..299

  def process_payment(service, %{correlation_id: correlation_id, amount: amount, inserted_at: inserted_at}) do
    try do
      processors()
      |> Map.get(service)
      |> then(
        &Finch.build(
          :post,
          "#{&1}/payments",
          [{"Content-Type", "application/json"}],
          Jason.encode!(%{"correlationId" => correlation_id, "amount" => amount, "requestedAt" => inserted_at})
        )
      )
      |> Finch.request(Pit.Finch, receive_timeout: @timeout)
      |> case do
        {:ok, %Finch.Response{status: status}} when status in @success_range ->
          {:ok, amount}
        {:ok, %Finch.Response{status: status}} -> {:error, "HTTP #{status}"}
        {:error, reason} -> {:error, reason}
        _ -> {:error, "unknown error"}
      end
    rescue
      e -> {:error, e}
    end
  end

  def get_processors_status do
    try do
      statuses = Enum.map(processors(), fn {service, url} ->
        case check_service_health(url) do
          {:ok, response_time} -> {service, %{failing: false, min_response_time: response_time}}
          {:error, _} -> {service, %{failing: true, min_response_time: 999999}}
        end
      end)
      {:ok, Map.new(statuses)}
    rescue
      e -> {:error, e}
    end
  end

  defp check_service_health(url) do
    start_time = System.monotonic_time(:millisecond)
    require Logger

    case Finch.build(:get, "#{url}/payments/service-health") |> Finch.request(Pit.Finch, receive_timeout: 5000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        end_time = System.monotonic_time(:millisecond)
        response_time = end_time - start_time

        case Jason.decode(body) do
          {:ok, %{"failing" => failing, "minResponseTime" => min_response_time}} ->
            Logger.info("🔍 HealthCheck: #{url} - failing: #{failing}, minResponseTime: #{min_response_time}")
            {:ok, response_time}
          {:error, _decode_error} ->
            {:error, "decode failed"}
        end

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, "HTTP #{status}, Body: #{body}"}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "unknown error"}
    end
  end

  defp processors do
    %{
      default: Application.get_env(:pit, :payment_processors)[:default_url] || "http://payment-processor-default:8080",
      fallback: Application.get_env(:pit, :payment_processors)[:fallback_url] || "http://payment-processor-fallback:8080"
    }
  end
end
