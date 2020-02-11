defmodule Bb do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: Bb,
      producer: [
        module: {Bb.Producer, 1000},
        transformer: {Bb.ProducerMessage, :transform, []},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 40,
          min_demand: 2,
          max_demand: 5,
        ]
      ],
    )
  end

  def handle_message(:default, %Message{data: data} = message, _context) do
    :poolboy.transaction(:uploader, fn(pid)->
      GenServer.call(pid, {:upload, data}, 30_000)
    end)

    message
  end
end
