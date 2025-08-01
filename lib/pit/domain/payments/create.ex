defmodule Pit.Domain.Payments.Create do
  require Logger
  alias Pit.Domain.Payments.PaymentsServer

  def process_payment_fast(payment_body) do
    case PaymentsServer.select_processor_with_load_balancing() do
      {:ok, processor, url} ->
        Logger.info("🔵 SELECTED PROCESSOR: #{processor}")
        Task.start(fn -> do_process_payment_async(payment_body, processor, url, 0) end)
        {:ok, "processing"}

      :error ->
        Logger.error("🔴 NO HEALTHY PROCESSOR AVAILABLE for #{payment_body["correlationId"]}")
        {:error, "no healthy processor"}
    end
  end

  def process_retry_queue do
    # Disabled retry queue - only store payments on definitive success
    :ok
  end

  defp do_process_payment_async(payment_body, processor, url, retry_count) do
    Logger.info("🔄 PROCESSING PAYMENT: #{payment_body["correlationId"]} via #{processor} (retry: #{retry_count})")

    payment_request = Map.put(payment_body, "requestedAt", DateTime.utc_now() |> DateTime.to_iso8601())

    case Finch.build(:post, "#{url}/payments", [{"content-type", "application/json"}], Jason.encode!(payment_request))
         |> Finch.request(MyFinch, receive_timeout: 10000, request_timeout: 10000, pool_timeout: 10000) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.info("📥 RECEIVED #{status}")
        case status do
          200 ->
            case handle_response_async(body) do
              :ok ->
                Logger.info("✅ RESPONSE VALIDATION PASSED: #{payment_body["correlationId"]}")
                store_result = store_payment_sync(payment_body, processor)
                case store_result do
                  :ok ->
                    Logger.info("💾 PAYMENT STORED SUCCESSFULLY: #{payment_body["correlationId"]} via #{processor}")
                  :error ->
                    Logger.error("❌ FAILED TO STORE PAYMENT: #{payment_body["correlationId"]}")
                end
                store_result
              :error ->
                Logger.error("❌ RESPONSE VALIDATION FAILED: #{payment_body["correlationId"]} - body: #{body}")
                # Don't store failed payments, don't retry
                :error
            end
          422 ->
            if String.contains?(body, "CorrelationId already exists") do
              Logger.info("🔄 DUPLICATE PAYMENT: #{payment_body["correlationId"]} already processed")
              # Don't store
              :ok
            else
              Logger.warning("⚠️ PAYMENT PROCESSOR ERROR #{status}: #{payment_body["correlationId"]} - #{body}")
              :error
            end
          _ ->
            Logger.warning("⚠️ PAYMENT PROCESSOR ERROR #{status}: #{payment_body["correlationId"]} - #{body}")
            :error
        end

      {:error, reason} ->
        Logger.error("🔴 PAYMENT PROCESSOR ERROR: #{payment_body["correlationId"]} - #{inspect(reason)}")
        # Retry on network errors
        case reason do
          %Mint.TransportError{reason: :timeout} ->
            Logger.warning("⏰ TIMEOUT - RETRYING ONCE: #{payment_body["correlationId"]}")
            retry_payment_once(payment_body, processor, url)
            :error
          %Mint.TransportError{reason: :closed} ->
            Logger.warning("🔌 CONNECTION CLOSED - RETRYING ONCE: #{payment_body["correlationId"]}")
            retry_payment_once(payment_body, processor, url)
            :error
          _ ->
            Logger.warning("❌ OTHER ERROR - NOT RETRYING: #{payment_body["correlationId"]}")
            :error
        end
    end
  rescue
    e ->
      Logger.error("💥 PAYMENT PROCESSING EXCEPTION: #{payment_body["correlationId"]} - #{inspect(e)}")
      :error
  end

  defp handle_response_async(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"message" => "payment processed successfully"}} ->
        :ok
      {:ok, %{"message" => message}} when is_binary(message) ->
        :ok
      {:error, decode_error} ->
        Logger.error("❌ RESPONSE VALIDATION FAILED: JSON decode error - #{inspect(decode_error)} - body: #{response_body}")
        :error
    end
  end

  defp store_payment_sync(payment_body, processor) do
    amount_cents = trunc(payment_body["amount"] * 100)

    payment_key = "payments:history:#{payment_body["correlationId"]}"
    payment_data = %{
      correlation_id: payment_body["correlationId"],
      amount: payment_body["amount"],
      amount_cents: amount_cents,
      processor: Atom.to_string(processor),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Atomic operation to prevent race conditions (sync)
    case Redix.pipeline(:redix, [
      ["SETNX", payment_key, Jason.encode!(payment_data)],
      ["EXPIRE", payment_key, "86400"]
    ]) do
      {:ok, [set_result, _expire_result]} ->
        if set_result == 1 do
          case Redix.pipeline(:redix, [
            ["INCR", "payments:summary:#{Atom.to_string(processor)}:total_requests"],
            ["INCRBY", "payments:summary:#{Atom.to_string(processor)}:total_amount_cents", amount_cents]
          ]) do
            {:ok, [requests, amount_cents]} ->
              Logger.info("✅ COUNTERS INCREMENTED")
              :ok
            {:error, error} ->
              Logger.error("❌ FAILED TO INCREMENT COUNTERS:")
              :error
            _ ->
              Logger.error("❌ FAILED TO INCREMENT COUNTERS")
              :error
          end
        else
          # Payment already existed, don't increment counters
          Logger.info("🔄 PAYMENT ALREADY EXISTS: #{payment_body["correlationId"]} - skipping counter increment")
          :ok
        end
      _ ->
        Logger.error("❌ FAILED TO STORE PAYMENT: #{payment_body["correlationId"]}")
        :error
    end
  end

  defp retry_payment_once(payment_body, processor, url) do
    # Check if payment was already successfully processed before retrying
    payment_key = "payments:history:#{payment_body["correlationId"]}"
    case Redix.command(:redix, ["EXISTS", payment_key]) do
      {:ok, 1} ->
        Logger.info("🔄 PAYMENT ALREADY PROCESSED - SKIPPING RETRY: #{payment_body["correlationId"]}")
        :ok
      {:ok, 0} ->
        Logger.info("🔄 RETRYING PAYMENT ONCE: #{payment_body["correlationId"]} via #{processor}")
        # Retry immediately without queue
        Task.start(fn ->
          Process.sleep(50)
          do_process_payment_async(payment_body, processor, url, 1)
        end)
        :ok
      _ ->
        Logger.error("❌ FAILED TO CHECK PAYMENT STATUS: #{payment_body["correlationId"]}")
        :error
    end
  end

end
