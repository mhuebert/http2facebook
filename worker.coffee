fs = require('fs')
phantom = require('phantom')
temp = require('temp')
rest = require("restler")

phantom.create (ph) ->

  jpgToPage = (jpgPath, cb) ->
    buffer = fs.readFileSync(jpgPath)

    r = rest.post "https://graph.facebook.com/#{process.env.page_id}/photos", 
      multipart: true
      data:
        source: rest.data("image.jpg", "image/jpeg", buffer)
        access_token: process.env.page_token
        fileUpload: true
    
    r.on "complete", (result, response) ->
      console.log result, response.statusCode, response.req?.path
      cb()


  ph.createPage (page) ->
    page.open "http://www.google.com", (status) ->
      console.log "opened google? ", status
      p = temp.path({suffix: '.jpg'})
      page.render p, (result) ->
        jpgToPage p, ->
          ph.exit()


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