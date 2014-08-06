fs = require('fs')
_ = require("underscore")
screenshot = require('url-to-image')
path = require("path")



temp = require('temp')
rest = require("restler")
Firebase = require("firebase")
commentMessage = require("./commentMessage")
{pipeline, log} = require("./pipeline")
___ = log

imageToAlbum = require("./middleware/imageToAlbum")
postAlbum = require("./middleware/postAlbum")
postAlbumBatch = require("./middleware/postAlbumBatch")
imageToAlbumRaw = require("./middleware/imageToAlbumRaw")

Fire = new Firebase(process.env.fire_url)
Fire.auth(process.env.firebase_secret)

wait = (t, fn) ->
  setTimeout fn, t*1000

Fire.child("stream").on "child_added", (snap) ->
  stream = _.extend snap.val(),
    key: snap.name()
    ref: snap.ref()
  handleJob {stream: stream}



handleJob = (job, cb) ->
  pipeline job, [
    validateJob
    startTimer
    # updateJob(started: true)
    getPost
    getImage
    imageToAlbumRaw
    postAlbumBatch
    # # hidePost
    # updateJob(complete: true)
  ], finished

updateJob = (data) ->
  (job, done) ->
    job.stream.ref.update data
    done(null, job)

startTimer = (job, done) ->
  job.startTime = Date.now()
  done(null, job)

finished = (err, job) ->
  if err
    console.log "Error:", err, job
    return
  if job?
    console.log "Finished job in #{((Date.now()-job.startTime)/1000).toFixed(1)}s"
  # console.log "finalValue", value

validateJob = (job, done) ->
  {stream} = job
  if true in [stream.started, stream.complete]
    return done("stop", "Stream already in progress")
  if !job.stream.post_id
    return done("readStream: No post id in job", job)
  if job.stream.comment_id
    return done("stop", "This is a comment")
  done(null, job)

getPost = (job, done) ->
  job.postId = job.stream.post_id
  r = rest.get "https://graph.facebook.com/v2.0/#{job.postId}",
    query:
      access_token: process.env.page_token
  r.on "success", (data, response) ->
    # console.log "getPost", result, response.statusCode, response.req?.path
    done null, _.extend(job, {post: data})

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

getImage = (job, done) ->
  return done("getImage: no link") if !job.post.link
  imagePath = temp.path({suffix: '.jpg'})
  screenshot(job.post.link, imagePath)    
    .then ->
      return done("getImage: File not saved!") if !fs.existsSync(imagePath)
      console.log job.imagePath = imagePath
      done(null, job)
    .fail(done, job)

createAlbum = (job, done) ->

  r = rest.post "https://graph.facebook.com/v2.0/#{process.env.page_id}/albums", 
    data:
      access_token: process.env.page_token
      name: job.post.name || job.post.caption || job.post.link
      description: job.post.description || ""
      no_story: true

  r.on "success", (data, response) -> 
    job.albumId = data.id
    done(null, job)

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)


postImage = (job, done) ->
  r = rest.post "https://graph.facebook.com/v2.0/#{process.env.page_id}/photos", 
    multipart: true
    data:
      source: rest.data("image.jpg", "image/jpeg", fs.readFileSync(job.imagePath))
      access_token: process.env.page_token
      fileUpload: true
      no_story: true

  r.on "success", (data, response) -> 
    job.imageResult = data
    done(null, job)

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

hidePost = (job, done) ->
  # get an access token error
  r = rest.post "https://graph.facebook.com/v2.0/#{job.postId}",
    is_hidden: true
    access_token: process.env.app_token

  r.on "success", (result, response) ->
    done(null, job)

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

postComment = (job, done) ->
  r = rest.post "https://graph.facebook.com/v2.0/#{job.postId}/comments",
    time = (Date.now() - job.startTime/1000).toFixed(1)
    message: "#{commentMessage(time)}\n\nhttps://www.facebook.com/JPGInternet/posts/"
    access_token: process.env.page_token
  
  r.on "success", (result, response) ->
    job.commentResult = result
    done(null, job)

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)