rest = require("restler")
fs = require('fs')

module.exports = (job, done) ->


  postImage = (n) ->
    time = (Date.now() - job.startTime)/1000
    if n == (job.imagePaths.length)
      return done(null, job)
    if n == -1
      imagePath = job.imagePath
      message = "Complete Snapshot"
    else
      imagePath = job.imagePaths[n]
      message = "#{n} of #{job.imagePaths.length}. #{time}s from start."

    r = rest.post "https://graph.facebook.com/v2.0/#{job.albumId}/photos", 
      multipart: true
      data:
        source: rest.data("image.jpg", "image/jpeg", fs.readFileSync(imagePath))
        message: message
        access_token: process.env.page_token
        fileUpload: true
        no_story: true

    r.on "success", (data, response) -> 
      job.imageResult = data
      postImage(n+1)
      # done(null, job)

    r.on "fail", (data, response) -> done(data, job)
    r.on "error", (err, response) -> done(err, job)

  postImage(-1)