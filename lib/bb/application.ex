defmodule Bb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Bb.Uploader

  defp poolboy_config do
    [
      {:name, {:local, :uploader}},
      {:worker_module, Uploader},
      {:size, 40},
    ]
  end

  def start(_type, _args) do
    metrics = [
      Telemetry.Metrics.counter("broadway.processor.message.stop.duration"),
      Telemetry.Metrics.sum("broadway.processor.message.stop.duration"),
      # Telemetry.Metrics.last_value("broadway.processor.message.stop.duration", unit: {:native, :millisecond}),
      Telemetry.Metrics.summary("broadway.processor.message.stop.duration", unit: {:native, :millisecond}),
      Telemetry.Metrics.distribution("broadway.processor.message.stop.duration", buckets: [200, 500, 1000], unit: {:native, :millisecond}),
    ]

    children = [
      :poolboy.child_spec(:uploader, poolboy_config(), []),
      {Bb.BroadwayReporter, metrics: metrics},
      Bb
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp handle_event([:broadway, :processor, :message, :stop], %{duration: duration}, metadata, _config) do
    total = System.convert_time_unit(duration, :nanosecond, :millisecond)

    IO.puts "message #{metadata.processor_key}: #{total}"
    duration
  end

  defp handle_event([:broadway, :processor, :stop], %{duration: duration}, metadata, _config) do
    total = System.convert_time_unit(duration, :nanosecond, :millisecond)

    IO.puts "processor #{metadata.name}: #{total}"
  end
end