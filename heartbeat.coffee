Firebase = require("firebase")
moment = require("moment")
rest = require("restler")
ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

ref.child("heartbeat").on "value", ->

heartbeat = ->
  time = moment(time).format('MMMM Do YYYY, h:mm:ss a')
  ref.child("heartbeat/image-grabber").set time, (err) ->
    console.log "Tick, #{time}", err

  r = rest.post process.env.event_server_url
  
  r.on "success", (result, response) ->

  r.on "fail", (data, response) -> 
    console.log "Event server down"
  r.on "error", (err, response) -> 
    console.log "Event server down"

setInterval heartbeat, 30*1000
heartbeat()