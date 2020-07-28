from(bucket: "monitoring_last")
|>filter(fn: (r) => r._measurement == "cpufreq" and r._field == "cur_freq" or r._field == "min_freq")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_value", "host", "_field", "cpu"])
|> pivot(rowKey:[], columnKey: ["_field"], valueColumn: "_value")
|> filter(fn: (r) => r.cur_freq < r.min_freq)
|> group(columns: ["host", "cpu"])
|> map(fn: (r) => ({
  min_freq: string(v: r.min_freq),
  _value: r.cur_freq,
  _type: "Error"
}))
|> group(columns: ["host", "cpu", "min_freq"])
