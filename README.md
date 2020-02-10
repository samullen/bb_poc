# Running

`iex -S mix`

The process will run automatically, uploading the file `file.txt` however many
times the `Bb.Producer` (see bb.ex) is defined to run.

# Metrics

Total counts: `:ets.lookup(:metrix, :counter)`
counts by process: `:ets.match_object(:metrix, {{:counter, :_}, :_})`
Time in MS by process: `:ets.match_object(:metrix, {{:sum, :_}, :_})`
Min/Max by process: `:ets.match_object(:metrix, {{:summary, :_}, :_})`
Distribution by process: `:ets.match_object(:metrix, {{:distribution, :_, :_}, :_})`
