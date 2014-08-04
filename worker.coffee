fs = require('fs')
phantom = require('phantom')
temp = require('temp')
rest = require("restler")
Firebase = require("firebase")

getMessage = (time) ->
  mList = [
    "Here you go. Moar!!! #{time}s."
    "Served you JPG Internet in #{time}s."
    "That was #{time} seconds of work over here."
    "Processing time: #{time} seconds."
    "Try drawing a website in #{time} seconds."
    "It was worth spending #{time} seconds on you."
    "#{time} seconds for JPG. JPG!"
    "moar JPG! #{time}s"
    "JPG Internet is for Sprint customers."
    "JPG Internet is a new frontier."
    "JPG FTW"
  ]
  i = Math.floor(Math.random()*(mList.length-1))
  mList[i]

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
      message: getMessage(time)
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
      page.open url, (status) ->
        console.log "opened #{url}?", status
        jpgPath = temp.path({suffix: '.jpg'})
        page.render jpgPath, (result) ->
          callback(jpgPath)
          # ph.exit()


  # rest.get "/#{post_id}?fields=name,link,message"
  # - phantom(link)
  # /
  # Get link from post
  # 

  # def text_to_fb
  #   with_JPG(url) do |txt|
  #     r = RestClient.post graph+endpoint,
  #                   :access_token => ENV["page_token"],
  #                   :message => txt
  #   end
  # end

  # # for comment, endpoint="#{objectId}/comments"
  # # , endpoint=ENV["page_id"]+"/photos"
  # def jpg_to_fb_comment (url, post_id, message="")
  #   with_JPG(url) do |jpg|
  #     r = RestClient.post "https://graph.facebook.com/#{post_id}/comments", 
  #                   :source => jpg, 
  #                   :fileUpload => true,
  #                   :multipart => true,
  #                   :published => true,
  #                   :message => message
  #   end
  # end