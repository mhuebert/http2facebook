Firebase = require("firebase")
moment = require("moment")
ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

heartbeat = ->
  time = moment(time).format('MMMM Do YYYY, h:mm:ss a')
  ref.child("heartbeat/image-grabber").set time, (err) ->
    console.log "Tick, #{time}", err
    
setInterval heartbeat, 30*1000