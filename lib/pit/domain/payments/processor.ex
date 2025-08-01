defmodule Pit.Domain.Payments.Processor do
  require Logger

  def health_check(:default) do
    url = System.get_env("PROCESSOR_DEFAULT_URL")
    Logger.info("Checking default processor health at: #{url}")
    do_check(url)
  end

  def health_check(:fallback) do
    url = System.get_env("PROCESSOR_FALLBACK_URL")
    Logger.info("Checking fallback processor health at: #{url}")
    do_check(url)
  end

  defp do_check(url) do
    try do
      case Finch.build(:get, "#{url}/payments/service-health")
           |> Finch.request(MyFinch, receive_timeout: 10000, request_timeout: 10000, pool_timeout: 5000) do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          Logger.info("Health check successful for #{url}")
          {:ok, body}

        {:ok, %Finch.Response{status: status, body: body}} ->
          Logger.warning("Health check failed with status #{status} for #{url}: #{body}")
          {:error, "HTTP #{status}"}

        {:error, reason} ->
          Logger.error("Health check error for #{url}: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Health check exception for #{url}: #{inspect(e)}")
        {:error, "exception"}
    end
  end
end
