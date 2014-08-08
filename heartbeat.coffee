Firebase = require("firebase")
moment = require("moment")
ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

heartbeat = ->
  time = Date.now()
  ref.child("heartbeat").set time, ->
    console.log "Tick, #{moment(time).format('MMMM Do YYYY, h:mm:ss a')}"
    
setInterval heartbeat, 30*1000