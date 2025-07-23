defmodule Pit.Payments.Status do
  def health_check do
    url = System.get_env("PROCESSOR_DEFAULT_URL")

    Finch.build(:get, "#{url}/payments/service-health")
    |> Finch.request(MyFinch)
    |> case do
      {:ok, response} ->
        IO.inspect(response.body, label: "Health Check Response")
        {:ok, response.body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
