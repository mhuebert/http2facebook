if process.env.NODETIME_ACCOUNT_KEY
  require("nodetime").profile
    accountKey: process.env.NODETIME_ACCOUNT_KEY


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

postAlbum = require("./middleware/postAlbum")
imageToAlbum = require("./middleware/imageToAlbum")

Fire = new Firebase(process.env.fire_url)
Fire.auth(process.env.firebase_secret)

require("./heartbeat")

# wait = (t, fn) ->
#   setTimeout fn, t*1000

# handleJob = (job, cb) ->
#   pipeline job, [
#     getImage
#     imageToAlbum
#   ], finished
# wait 0.2, -> handleJob {post: {link: "https://www.google.ca/webhp?ion=1&espv=2&ie=UTF-8#q=where%20can%20I%20find%20some%20food%20and%20water"}}

Fire.child("stream").endAt(0).on "child_added", (snap) ->
  stream = _.extend snap.val(),
    key: snap.name()
    ref: snap.ref()
    priority: snap.getPriority()
  # console.log _(stream).omit("ref")
  handleJob {stream: stream}

handleJob = (job, cb) ->
  pipeline job, [
    validateJob
    startTimer
    markJobStart
    getPost
    getImage
    imageToAlbum
    postAlbum
    # # hidePost
    markJobComplete
  ], finished

startTimer = (job, done) ->
  job.startTime = (job.stream.__time*1000) || Date.now()
  done(null, job)

markJobStart = (job, done) ->
  job.stream.ref.update {started: true}, ->
    done(null, job)

markJobComplete = (job, done) ->
  ref = job.stream.ref
  ref.update {complete: true}
  ref.setPriority 3
  done(null, job)

finished = (err, job) ->
  ref = job.stream.ref
  if err == "skip"
    console.log "Skipped because in progress", job
    return
  if err == "complete"
    console.log "Marked job complete", job
    ref.setPriority 3
    return
  if err?
    console.log "Error:", err, job
    if job?.stream
      job.stream = _(job.stream).omit("ref")
    ref.child("errors").push [err, job]
    ref.setPriority 2
    return
  if job?
    console.log "Finished job in #{((Date.now()-job.startTime)/1000).toFixed(1)}s"

validateJob = (job, done) ->
  {stream} = job

  if true in [stream.started, stream.complete]
    return done("skip", job)
  if !job.stream.post_id
    return done("No post id in job", job)
  if job.stream.comment_id
    return done("complete", job)
  done(null, job)

getPost = (job, done) ->
  job.postId = job.stream.post_id
  r = rest.get "https://graph.facebook.com/v2.0/#{job.postId}",
    query:
      access_token: process.env.page_token
  r.on "success", (data, response) ->
    if !data.link
      return done("No Link!", job)
    done null, _.extend(job, {post: data})

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

getImage = (job, done) ->
  return done("getImage: no link") if !job.post.link
  imagePath = temp.path({suffix: '.jpg'})
  screenshot(job.post.link, imagePath, {width: 1280, maxHeight: 28000})    
    .fail (err) ->
      console.log "getImage: Fail"
      done(err, job)
    .then ->
      return done("getImage: Done, File not saved!", arguments) if !fs.existsSync(imagePath)
      job.imagePath = imagePath
      done(null, job)
    

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