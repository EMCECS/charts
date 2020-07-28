from(bucket: "monitoring_last")
|>filter(fn: (r) => r._measurement == "cpufreq" and r._field == "cur_freq" or r._field == "min_freq")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_value", "host", "_field", "cpu"])
|> pivot(rowKey:[], columnKey: ["_field"], valueColumn: "_value")
|> filter(fn: (r) => r.cur_freq < r.min_freq)
|> map(fn: (r) => ({
  _reason: "Hardware failure in the CPU chipset or motherboard.",
  _message: "RAP071 - Detected a CPU core " + r.cpu + " running under(" + string(v: r.cur_freq) + "MHz) the configured MHz(" + string(v: r.min_freq) + ") threshold on host " + r.host,
  _type: "Error"
}))
