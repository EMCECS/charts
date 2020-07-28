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
|> map(fn: (r) => ({
 _reason: "Filesystem mounted by /var path has large files or docker volumes consume a lot of space",
 _message: "Thresholds exceeded, usable space " + string(v:r._value/1024/1024/1024) + "GB on root fs are less than threshold on node " + r.host,
 _type:
   if r._value < error_threshold then "Error"
   else "Warning"
}))
