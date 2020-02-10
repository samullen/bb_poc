defmodule Bb.Producer do
  use GenStage

  def start_link(number) do
    GenStage.start_link(Bb.Producer, number)
  end

  def init(counter) do
    {:producer, Enum.to_list(1..counter)}
  end

  def handle_demand(demand, state) when demand > 0 do
    {head, tail} = Enum.split(state, demand)

    {:noreply, head, tail}
  end
end
