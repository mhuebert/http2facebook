# rest = require("restler")

# ping = ->
#   console.log "Tick, #{moment().format('MMMM Do YYYY, h:mm:ss a')}"
#   r = rest.post process.env.event_server_url

#   r.on "success", (data, response) -> 
#     console.log "Event server up"

#   r.on "fail", (data, response) -> console.log data, "Events server not responding"
#   r.on "error", (err, response) -> console.log err, "Events server not responding"
# setInterval ping, 180*1000
# ping()



Firebase = require("firebase")
Fire = new Firebase(process.env.fire_url)
Fire.auth(process.env.firebase_secret)
moment = require("moment")


ref = Fire.child("heartbeat")

ref.on "value", ->

heartbeat = ->
  time = Date.now()
  ref.child("heartbeat").set time, ->
    console.log "Tick, #{moment(time).format('MMMM Do YYYY, h:mm:ss a')}"

setInterval heartbeat, 30*1000
heartbeat()
