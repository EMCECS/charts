// 24 hours in nanoseconds
offset_nanos = 86400000000000

// subtract 24 hours from current {{ .Start }} time to get all possible hosts
start_with_offset = duration(v: uint(v: {{ .Start }}) - uint(v: offset_nanos))

from(bucket: "monitoring_op")
|> range(start: -start_with_offset, stop: {{ .Stop }})
|> filter(fn: (r) => r._measurement == "mem" and r._field == "free")
|> last()
|> keep(columns: ["host", "_value", "_time"])
|> last()
// get metrics for only those hosts whose metrics are not included in [{{ .Start }}, {{ .Stop }}] interval
|> range(start: -start_with_offset, stop: {{ .Start }})
|> group(columns: ["host"])
|> map(fn: (r) => ({
  _value: r._value,
  _type: "Critical"
}))