defmodule TrueAnomalyWeb.Router do
  use TrueAnomalyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TrueAnomalyWeb do
    pipe_through :api
  end
end
