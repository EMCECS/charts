// error threshold 10GB
error_threshold = 10737418240
// warning threshold 15GB
warning_threshold = 16106127360

from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement == "kubernetes_node" and r._field == "fs_available_bytes")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_value", "host"])
|> filter(fn: (r) => r._value < warning_threshold)
|> group(columns: ["host"])
|> map(fn: (r) => ({
 _value: r._value/1024/1024/1024,
 _type:
   if r._value < error_threshold then "Error"
   else "Warning"
}))
