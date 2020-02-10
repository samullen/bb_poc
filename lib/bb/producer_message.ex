defmodule Bb.ProducerMessage do
  def transform(event, _opts) do
    message = %Broadway.Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, event}
    }
  end

  def ack(_ref, _successes, _failures) do
    :ok
  end
end
