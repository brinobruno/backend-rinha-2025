defmodule Pit.Payments.Get do
  import Ecto.Query, only: [from: 2]

  alias Pit.Repo
  alias Pit.Payments.Payment

  def call(params) do
    from_iso = params["from"]
    to_iso = params["to"]

    with {:ok, from_dt, _} <- DateTime.from_iso8601(from_iso),
         {:ok, to_dt, _} <- DateTime.from_iso8601(to_iso) do
      query =
        from p in Payment,
          where: p.inserted_at >= ^from_dt and p.inserted_at <= ^to_dt,
          where: p.processor in ["default", "fallback"],
          group_by: p.processor,
          select: %{
            processor: p.processor,
            total_requests: count(p.id),
            total_amount: sum(p.amount)
          }

      result = Repo.all(query)

      default_processor = Enum.find(result, fn p -> p.processor == "default" end)
      fallback_processor = Enum.find(result, fn p -> p.processor == "fallback" end)

      response = %{
        default: %{
          totalRequests: (default_processor && default_processor.total_requests) || 0,
          totalAmount: (default_processor && default_processor.total_amount) || 0
        },
        fallback: %{
          totalRequests: (fallback_processor && fallback_processor.total_requests) || 0,
          totalAmount: (fallback_processor && fallback_processor.total_amount) || 0
        }
      }

      {:ok, response}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
