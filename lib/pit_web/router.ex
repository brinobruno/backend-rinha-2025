defmodule PitWeb.Router do
  use PitWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PitWeb do
    pipe_through :api

    post "/payments", PaymentController, :create
    get "/payments-summary", PaymentController, :get
    get "/health", PaymentController, :health
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:pit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application is not yet production-ready, you can use
    # Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: PitWeb.Telemetry
    end
  end
end
