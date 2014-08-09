Firebase = require("firebase")
moment = require("moment")
rest = require("restler")
ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

ref.child("heartbeat").on "value", -> 

time = -> moment().format('MMMM Do YYYY, h:mm:ss a')

setInterval ->
  ref.child("heartbeat/#{process.env.other_app}").set time()
, 1000

setInterval ->
  r = rest.get process.env.event_server_url
  r.on "success", (result, response) ->
  r.on "fail", -> handleFail
  r.on "error", -> handleFail
, 50*1000

handleFail = -> 
  console.log "Image server down"
  ref.child("heartbeat/#{process.env.other_app}").set time()