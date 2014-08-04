fs = require('fs')
phantom = require('phantom')
temp = require('temp')
rest = require("restler")
Firebase = require("firebase")
commentMessage = require("./commentMessage")

phantom.create (ph) ->

  Fire = new Firebase(process.env.fire_url)
  Fire.auth(process.env.firebase_secret)

  Fire.child("stream").on "child_added", (snap) ->
    item = snap.val()
    console.log "beginning... #{item.post_id}"
    if true in [item.started, item.complete] or item.type == 'photo'
      return
    snap.ref().update(started: true)
    handlePost item.post_id, ->
      snap.ref().update(complete: true)


  # Debugging messages - "debug mode"?
  # Better way to handle async: promises, or async library?
  # How to handle errors: catch them, report them, log them?

  # getPost
  # getJpg
  # postToPage
  # addComment

  handlePost = (id, callback) ->
    t1 = Date.now()
    getPost id, (post) ->
      if !post.link
        return
      getJpg post.link, (jpgPath) ->
        postToPage jpgPath, ->
          console.log "Gonna send comment..."
          time = ((Date.now() - t1)/1000).toFixed(1)
          addComment id, time, ->
            callback()
            console.log "Finished at last... #{id}"

  postToPage = (jpgPath, callback) ->
    buffer = fs.readFileSync(jpgPath)

    r = rest.post "https://graph.facebook.com/v2.0/#{process.env.page_id}/photos", 
      multipart: true
      data:
        source: rest.data("image.jpg", "image/jpeg", buffer)
        access_token: process.env.page_token
        fileUpload: true
        no_story: true
    
    r.on "complete", (result, response) ->
      console.log "postToPage", result, response.statusCode, response.req?.path
      if !result.id
        return
      callback()

  addComment = (postId, time, callback) ->
    r = rest.post "https://graph.facebook.com/v2.0/#{postId}/comments",
      attachment_id: postId
      message: commentMessage(time)
      access_token: process.env.page_token
    r.on "complete", (result, response) ->
      console.log "addComment", result, response.statusCode, response.req?.path
      callback()


  getPost = (id, callback) ->
    r = rest.get "https://graph.facebook.com/v2.0/#{id}",
      query:
        access_token: process.env.app_token
    r.on "complete", (result, response) ->
      console.log "getPost", result, response.statusCode, response.req?.path
      if !result.id
        return
      callback(result)
  
  getJpg = (url, callback) ->
    ph.createPage (page) ->
      page.onError = (message, trace) ->
        console.log "Phantom Error", message, trace
      page.open url, (status) ->
        if status != 'success'
          console.log "ERROR: PhantomJS unable to access network"
        else
          console.log "PhantomJS connected to #{url}"
        jpgPath = temp.path({suffix: '.jpg'})
        setTimeout ->
          page.render jpgPath, (result) ->
            console.log "phantom:", result, jpgPath
            setTimeout ->
              callback(jpgPath)
            , 500
            # ph.exit()
        , 3000