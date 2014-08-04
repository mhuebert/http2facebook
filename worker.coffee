fs = require('fs')
_ = require("underscore")
screenshot = require('url-to-image')

temp = require('temp')
rest = require("restler")
Firebase = require("firebase")
commentMessage = require("./commentMessage")
{pipeline, log} = require("./pipeline")
___ = log

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
  t1 = Date.now()
  pipeline job, [
    startJob
    readStream
    getPost
    getImage
    postImage
    endJob
    postComment
  ], finished

startJob = (job, done) ->
  job.stream.ref.update started: true
  job.startTime = Date.now()
  done(null, job)

endJob = (job, done) ->
  job.stream.ref.update complete: true
  job.endTime = Date.now()
  done(null, job)

finished = (err, value) ->
  if err
    console.log "Error:", err
    return
  console.log "finalValue", value

readStream = (job, done) ->
  {stream} = job
  if true in [stream.started, stream.complete]
    return done("stop", "Stream already in progress")
  if !job.stream.post_id
    return done("readStream: No post id in job")

  job.postId = stream.post_id

  done(null, job)

getPost = (job, done) ->
  r = rest.get "https://graph.facebook.com/v2.0/#{job.postId}",
    query:
      access_token: process.env.app_token
  
  r.on "success", (data, response) ->
    # console.log "getPost", result, response.statusCode, response.req?.path
    done null, _.extend(job, {post: data})

  r.on "fail", (data, response) -> done(data)
  r.on "error", (err, response) -> done(err)


getImage = (job, done) ->
  return done("getImage: no link") if !job.post.link
  imagePath = temp.path({suffix: '.jpg'})
  screenshot(job.post.link, imagePath)
    .fail(done)
    .done -> 
      return done("getImage: File not saved!") if !fs.existsSync(imagePath)
      job.imagePath = imagePath
      done(null, job)

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

  r.on "fail", (data, response) -> done(data)
  r.on "error", (err, response) -> done(err)

postComment = (job, done) ->
  r = rest.post "https://graph.facebook.com/v2.0/#{job.postId}/comments",
    attachment_id: job.postId
    time = (Date.now() - job.startTime/1000).toFixed(1)
    message: commentMessage(time)
    access_token: process.env.page_token
  
  r.on "success", (result, response) ->
    job.commentResult = result
    done(null, job)

  r.on "fail", (data, response) -> done(data)
  r.on "error", (err, response) -> done(err)