Firebase = require("firebase")
moment = require("moment")
rest = require("restler")
ref = new Firebase(process.env.fire_url)
ref.auth(process.env.firebase_secret)

time = -> moment().format('MMMM Do YYYY, h:mm:ss a')

Cron = require("cron").CronJob

new Cron '* * * * * *', ->
  ref.child("heartbeat/html2facebook").set time()
, null, true