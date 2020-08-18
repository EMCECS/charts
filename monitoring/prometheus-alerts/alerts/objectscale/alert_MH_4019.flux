// Simple check for telegraf system metrics availability
// In fact by such query we only checking liveness of telegraf component

import "csv"

// fictive data to handle empty response case
d = "#datatype,string,long,long
#group,false,false,false
#default,_result,,
,result,table,_value
,,0,0
"

f = csv.from(csv: d)

m = from(bucket: "monitoring_op")
|> filter(fn: (r) => r._measurement =~ /tsdb_telegraf_internal_.*/)
|> range(start: {{ .Start }}, stop: {{ .Stop }})
|> last()
|> group()

union(tables:[m,f])
|> count()
// we have one fictive record for case of no data from m query, so compare with 2
|> filter(fn: (r) => r._value < 2)
|> map(fn: (r) => ({
// keep value to not fail in process.tmpl
    _value: r._value,
    _reason: "No data is pushed to the monitoring framework for the last 30 minutes",
    _message: "Data recorded in TSDB is lagging by 30 mins",
    _type: "Critical"
  }))
