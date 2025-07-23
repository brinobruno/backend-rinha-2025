defmodule Pit do
  @moduledoc """
  Pit keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def request_hexpm do
    url = System.get_env("PROCESSOR_DEFAULT_URL")

    Finch.build(:get, "#{url}/payments/service-health")
    |> Finch.request(MyFinch)
  end
end
