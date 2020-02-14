defmodule Bb.Data do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, nil, name: Data)
  end

  @impl true
  def init(_) do
    data = File.read!("file.txt")

    {:ok, data}
  end

  def get, do: GenServer.call(Data, :get)

  def handle_call(:get, _from, state), do: {:reply, state, state}
end
