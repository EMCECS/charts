import "generate"
generate.from(start:2010-01-24T20:27:22.505751285Z,stop:2018-05-24T20:27:22.505751285Z,count:10000,fn:(n) =>n*100)
|> last()
|> map(fn: (r) => ({
 _reason: "This is dumb alert always triggered",
 _message: "volume is full",
 _type: "Critical",
}))
