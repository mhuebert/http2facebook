rest = require("restler")
moment = require("moment")

ping = ->
  console.log "Tick, #{moment().format('MMMM Do YYYY, h:mm:ss a')}"
  r = rest.post process.env.event_server_url

  r.on "success", (data, response) -> 
    console.log "Event server up"

  r.on "fail", (data, response) -> console.log data, "Events server not responding"
  r.on "error", (err, response) -> console.log err, "Events server not responding"
setInterval ping, 180*1000
ping()