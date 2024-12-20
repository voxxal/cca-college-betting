defmodule CcaCollegeBetting.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CcaCollegeBettingWeb.Telemetry,
      # Start the Ecto repository
      CcaCollegeBetting.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: CcaCollegeBetting.PubSub},
      # Start Finch
      {Finch, name: CcaCollegeBetting.Finch},
      # Start the Endpoint (http/https)
      CcaCollegeBettingWeb.Endpoint
      # Start a worker by calling: CcaCollegeBetting.Worker.start_link(arg)
      # {CcaCollegeBetting.Worker, arg}
    ]
    CcaCollegeBetting.Cache.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CcaCollegeBetting.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CcaCollegeBettingWeb.Endpoint.config_change(changed, removed)
    :ok
  end

 end
