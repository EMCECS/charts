// should be defined by user and minimal period 1h
thrsh_warning = 90
thrsh_error = 95
thrsh_critical = 99

// supposing that min alert period will be 1h: 60/5=12 points per h
// also suppose that last point may be not always present so take 11 points in row to trigger alert
points_to_trig = 11

a = from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_idle")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> map(fn: (r) => ({_value: 100.0 - r._value, _time: r._time}))
|> keep(columns: ["_time", "host", "_value"])
|> group(columns: ["host"])

warn = a
|> stateCount(fn:(r) => r._value > thrsh_warning)
|> rename(columns: {stateCount: "warn"})
|> last()

err = a
|> stateCount(fn:(r) => r._value > thrsh_error)
|> rename(columns: {stateCount: "err"})
|> last()

crit = a
|> stateCount(fn:(r) => r._value > thrsh_critical)
|> rename(columns: {stateCount: "crit"})
|> last()

all = join(tables: {warn: warn, err: err}, on: ["host", "_value", "_time"])

join(tables: {all: all, crit: crit}, on: ["host", "_value", "_time"])
|> filter(fn: (r) => r.warn >= points_to_trig)
|> group(columns: ["host"])
|> map(fn: (r) => ({
  _value: r._value,
  _type:    if r.crit >= points_to_trig then "Critical"
    else if r.err >= points_to_trig then "Error"
    else "Warning"}))
