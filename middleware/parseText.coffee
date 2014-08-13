extractor = require 'unfluff'
fs = require 'fs'
rest = require("restler")

module.exports = (job, done) ->
  console.log job
  console.log textPath = job.imagePath+'.txt'
  fs.exists textPath, (exists) ->
    if exists
      fs.readFile textPath, {encoding: 'utf8'}, (err, txt) ->
        postText extractor(txt).text

  postText = (text) ->
    r = rest.post "https://graph.facebook.com/v2.0/#{job.postId}/comments",
      data:
        access_token: process.env.page_token
        message: "Text Content: \n\n"+text

    r.on "success", (data, response) ->
      job.textResult = data
      done(null, job)

    r.on "fail", (data, response) ->
      done(data, job)
    r.on "error", (err, response) ->
      done(err, job)
