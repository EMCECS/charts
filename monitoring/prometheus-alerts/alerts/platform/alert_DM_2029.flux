// 8GB
threshold = 8589934592

from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement == "procstat" and r._field == "memory_vms" and r.process_name == "dockerd")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_value", "host"])
|> filter(fn: (r) => r._value > threshold)
|> group(columns: ["host"])
|> map(fn: (r) => ({
  _value: r._value,
  _type: "Critical"
}))
