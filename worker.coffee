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
postText = require("./middleware/postText")

Fire = new Firebase(process.env.fire_url)
Fire.auth(process.env.firebase_secret)

require("./heartbeat")

wait = (t, fn) ->
  setTimeout fn, t*1000

# testJob = 
#   post:
#     link: "https://twitter.com/jpginternet/status/499548497482629121"
#   postId: 1449635838646664

# handleJob = (job, cb) ->
#   pipeline job, [
#     getPageContents
#     # imageToAlbum
#     # postAlbum
#     parseText
#   ], finished
# wait 0.2, -> handleJob testJob

doStream = (key) ->
  Fire.child(key).once "value", handleSnapshot

handleSnapshot = (snap) ->
  if snap.val() == null
    return
  stream = _.extend snap.val(),
    key: snap.name()
    ref: snap.ref()
    priority: snap.getPriority()
  handleJob {stream: stream}

# streams = []
# for stream in streams
#   doStream(stream)
doStream("stream/140805117883ea99f5f83b12351518b2bc0ac27719")

# Fire.child("stream").on "child_added", handleSnapshot

handleJob = (job, cb) ->
  pipeline job, [
    # validateJob
    startTimer
    markJobStart
    getPost
    getPageContents
    # (job, done) -> console.log 
    imageToAlbum
    postAlbum
    postText
    moveJobToPath("complete")
  ], finished

startTimer = (job, done) ->
  job.startTime = (job.stream.__time*1000) || Date.now()
  done(null, job)

markJobStart = (job, done) ->
  job.stream.ref.update {started: true}, ->
    done(null, job)

moveJobToPath = (path) ->
  (job, done) ->
    {ref, key} = job.stream
    done("Ref and key not set!", job) if !ref or !key
    stream = _(job.stream).omit('ref', 'key', 'priority')
    console.log "moving to #{path}/#{key}"
    Fire.child("#{path}/#{key}").set stream, (err) ->
      if err?
        console.log "ERROR moving #{key}"
        return
      console.log "Moved successfully"
      ref.set null, (err) ->
        console.log "Removed original"


finished = (err, job) ->
  ref = job.stream?.ref
  if err == "skip"
    console.log "Skipped because in progress", job
    return
  if err == "complete"
    console.log "Mark job complete", job
    return moveJobToPath("complete")(job, ->)
    return
  if err? and ref?
    job.stream = _(job.stream).omit("ref")
    loggedJob = {}
    for key, val of job
      loggedJob[key] = val
      if key == "stream"
        loggedJob[key] = _(val).omit("ref")

    console.log "Error:", err, job
    ref.child("errors").push [err, loggedJob], ->
      return moveJobToPath("error")(job, ->)
  if job?
    console.log "Finished job in #{((Date.now()-job.startTime)/1000).toFixed(1)}s"

validateJob = (job, done) ->
  {stream} = job

  if stream.complete == true
    return moveJobToPath("complete")(job, done)
  
  if 'errors' in _(stream).keys()
    return moveJobToPath("error")(job, done)

  if stream.started == true 
    return done("skip", job)

  if !job.stream.post_id
    return done("No post id in job", job)

  if job.stream.comment_id
    return moveJobToPath("is-comment")(job, done)
  done(null, job)

getPost = (job, done) ->
  job.postId = job.stream.post_id
  r = rest.get "https://graph.facebook.com/v2.0/#{job.postId}",
    query:
      access_token: process.env.page_token
  r.on "success", (data, response) ->
    if !data.link
      return moveJobToPath("noLink")(job, done)
    done null, _.extend(job, {post: data})

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

getPageContents = (job, done) ->
  return moveJobToPath("no-link")(job, done) if !job.post.link
  imagePath = temp.path({suffix: '.jpg'})
  screenshot(job.post.link, imagePath, {width: 1280, maxHeight: 28000})    
    .fail (err) ->
      console.log "getImage: Fail"
      done(err, job)
    .then ->
      return done("getImage: Done, File not saved!", job) if !fs.existsSync(imagePath)
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