// 8GB
threshold = 8589934592

from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement == "procstat" and r._field == "memory_vms" and r.process_name == "dockerd")
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> keep(columns: ["_value", "host"])
|> filter(fn: (r) => r._value > threshold)
|> map(fn: (r) => ({
  _reason: "A defect in Docker 1.9.1 where large amounts of standard out while in a Docker Container causes the Docker PID to grow and not release memory",
  _message: "Docker Memory over threshold 8GB on node " + r.host,
  _type: "Critical"
}))
