# Backblaze Proof of Concept

## Setup

1. Copy the `config/config.exs.example` to `config/config.exs`
2. Edit `config/config.exs` adding your backblaze authorization
3. `mix deps.get`

## Running

The easiest way to run this is in the console:

`iex -S mix`

The process will start automatically, uploading the file `file.txt` however many
times the `Bb.Producer` (see bb.ex) is defined to run.

## Metrics

From the console, you can retrieve the following metrics using the corresponding
commands:

- Total counts: `:ets.lookup(:metrix, :counter)`
- Counts by process: `:ets.match_object(:metrix, {{:counter, :_}, :_})`
- Time in MS by process: `:ets.match_object(:metrix, {{:sum, :_}, :_})`
- Min/Max by process: `:ets.match_object(:metrix, {{:summary, :_}, :_})`
- Distribution by process: `:ets.match_object(:metrix, {{:distribution, :_, :_}, :_})`
