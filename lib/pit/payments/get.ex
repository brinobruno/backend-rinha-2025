defmodule Pit.Payments.Get do
  import Ecto.Query, only: [from: 2]

  alias Pit.Repo
  alias Pit.Payments.Payment

  def call do
    query =
      from p in Payment,
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
        totalRequests: default_processor.total_requests,
        totalAmount: default_processor.total_amount
      },
      fallback: %{
        totalRequests: fallback_processor.total_requests,
        totalAmount: fallback_processor.total_amount
      }
    }

    {:ok, response}
  rescue
    e -> {:error, Exception.message(e)}
  end
end
