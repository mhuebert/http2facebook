extractor = require 'unfluff'
fs = require 'fs'

module.exports = (job, done) ->
  textPath = job.imagePath+'.txt'
  fs.exists textPath, (exists) ->
    if exists
      fs.read textPath, (err, txt) ->
        postText extractor(txt).text

postText = (text) ->
  r = rest.post "https://graph.facebook.com/v2.0/",
    multipart: true
    data:
      access_token: process.env.page_token
      method: "POST"
      relative_url:"/#{job.postId}/comments"
      body: "message=#{text}"

  r.on "success", (data, response) ->
    job.textResult = data
    done(null, job)

  r.on "fail", (data, response) ->
    done(data, job)
  r.on "error", (err, response) ->
    done(err, job)
