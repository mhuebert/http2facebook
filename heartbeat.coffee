Firebase = require("firebase")
moment = require("moment")
rest = require("restler")

# Heroku = require('heroku-client')
# heroku = new Heroku({ token: process.env.heroku_api })

ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

heartbeat = ->
  time = moment(time).format('MMMM Do YYYY, h:mm:ss a')
  ref.child("heartbeat/image-grabber").set time, (err) ->
    console.log "Tick, #{time}", err

  r = rest.post process.env.event_server_url
  
  r.on "success", (result, response) -> 
    failedAttempts = 0

  r.on "fail", handleFail
  r.on "error", handleFail

# failedAttempts = 0
handleFail = ->
  console.log "Event server down"
#   failedAttempts += 1
#   # if failedAttempts == 3
#     # heroku.delete()

# heroku.apps().list().then (apps) -> console.log apps; console.log 1;
# console.log 'here'
# heroku.request
#   method: 'DELETE',
#   path: "/apps/#{process.env.other_app}/dynos"
# , (err, response) ->
#   console.log arguments

# heroku.delete("apps/#{process.env.other_app}/dynos")

setInterval heartbeat, 20*1000
heartbeat()