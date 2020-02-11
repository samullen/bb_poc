defmodule Bb.BroadwayReporter do
  use GenServer


  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum, Summary}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:metrics])
  end

  def init(metrics) do
    Process.flag(:trap_exit, true)

    :ets.new(:metrix, [:named_table, :public, :set, {:write_concurrency, true}])
    groups = Enum.group_by(metrics, & &1.event_name)

    for {event, metrics} <- groups do
      id = {__MODULE__, event, self()}
      :telemetry.attach(id, event, &handle_event/4, metrics)
    end

    {:ok, Map.keys(groups)}
  end

  def handle_event(_event_name, measurements, metadata, metrics) do
    metrics
    |> Enum.map(&(handle_metric(&1, measurements, metadata)))
  end

  def handle_metric(%Counter{}, _measurements, metadata) do
    :ets.update_counter(:metrix, :counter, 1, {:counter, 0})
    :ets.update_counter(:metrix, {:counter, metadata.name}, 1, {:counter, 0})
  end

  def handle_metric(%Sum{}, %{duration: duration}, metadata) do
    duration = System.convert_time_unit(duration, :nanosecond, :millisecond)
    key = {:sum, metadata.name}

    :ets.update_counter(:metrix, key, duration, {key, 0})
  end

  def handle_metric(%Summary{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    key = {:summary, metadata.name}

    summary =
      case :ets.lookup(:metrix, key) do
        [{key, {min, max}}] ->
          {
            min(min, duration),
            max(max, duration)
          }

        _ ->
          {duration, duration}
      end

    :ets.insert(:metrix, {key, summary})
  end

  def handle_metric(%Distribution{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    key = {:distribution, metadata.name}

    update_distribution(metric.buckets, metadata.name, duration)
  end

  defp update_distribution([], name, _duration) do
    key = {:distribution, name, "1000+"}
    :ets.update_counter(:metrix, key, 1, {key, 0})
  end

  defp update_distribution([head|_buckets], name, duration) when duration <= head do
    key = {:distribution, name, head}
    :ets.update_counter(:metrix, key, 1, {key, 0})
  end

  defp update_distribution([_head|buckets], name, duration) do
    update_distribution(buckets, name, duration)
  end

  def terminate(_, events) do
    events
    |> Enum.each(&(:telemetry.detach({__MODULE__, &1, self()})))

    :ok
  end

  defp extract_measurement(metric, measurements) do
    case metric.measurement do
      fun when is_function(fun, 1) ->
        fun.(measurements)

      key ->
        measurements[key]
    end
  end
end
