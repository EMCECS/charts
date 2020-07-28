warn_threshold = 0.7
error_threshold = 0.75
critical_threshold = 0.8

from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement == "linux_sysctl_fs" and (r._field == "file-nr" or r._field == "file-max"))
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_time", "_value", "host", "_field"])
|> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
|> map(fn: (r) => ({
      host: r.host,
      _value: float(v: r["file-nr"]) / float(v: r["file-max"])
   }))
|> filter(fn: (r) => r._value >= warn_threshold)
|> map(fn: (r) => ({
 _reason: "One or more processes have a large amount of open files that is causing the node to approach the maximum number of open file descriptors allowed",
 _message: "Number of open file descriptors is above threshold. Node: " + r.host,
 _type:
   if r._value >= warn_threshold and r._value < error_threshold then "Warning"
   else if r._value >= error_threshold and r._value < critical_threshold then "Error"
   else "Critical"
}))
