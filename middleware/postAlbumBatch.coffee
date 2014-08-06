rest = require("restler")
fs = require('fs')
commentMessage = require("../commentMessage")


module.exports = (job, done) ->
  # requires: job.post (.link, .name, .description)

  pad = (number) ->
    if number < 10 and job.imagePaths > 9
      return ("0"+number)
    number
  time = (Date.now() - job.startTime)/1000
  album =
    name: job.post.name || job.post.caption || job.post.link
    message: "Processed in #{time} seconds.\n\n #{job.post.description}"
  batch = [
    {method: "POST", name: "create-album", relative_url: "/#{process.env.page_id}/albums", body: "name=#{album.name}&description=#{album.message}"}
    {method: "POST", name: "name-0", relative_url: "/{result=create-album:$.id}/photos", attached_files: "file_full", body: "message=#{job.post.link}"}
  ]
  
  data =
    fileUpload: true
    access_token: process.env.page_token
    file_full: rest.data(job.imagePath, "image/jpeg", fs.readFileSync(job.imagePath))

  for imagePath, index in job.imagePaths
    i = index + 1
    batch.push {
      method: "POST", 
      name: "name-#{i}", 
      relative_url: "/{result=create-album:$.id}/photos", 
      attached_files: "file#{i}", 
      body: "message=#{pad(i)} of #{job.imagePaths.length}.\n\n#{job.post.link} {result=name-#{i-1}:$.message}&no_story=1"}
    data["file"+i] = rest.data(imagePath, "image/jpeg", fs.readFileSync(imagePath))
  

  time = ((Date.now() - job.startTime)/1000).toFixed(1)
  comment = commentMessage(time)

  if job.postId
    if job.imagePaths.length > 0
      batch.push {method: "POST", relative_url:"/#{job.postId}/comments", body: "message=\n\n#{comment} Preview: https://www.facebook.com/{result=name-1:$.id}"}
      batch.push {method: "POST", relative_url:"/#{job.postId}/comments", body: "message=\n\nFull Album (#{job.imagePaths.length} images): https://www.facebook.com/{result=create-album:$.id}"}
    else
      batch.push {method: "POST", relative_url:"/#{job.postId}/comments", body: "message=\n\n#{comment} https://www.facebook.com/{result=name-1:$.id}"}      

  data.batch = JSON.stringify(batch)

  r = rest.post "https://graph.facebook.com/v2.0/",
    multipart: true
    data: data

  r.on "success", (data, response) -> 
    job.albumResult = data
    done(null, job)

  r.on "fail", (data, response) -> done(data, job)
  r.on "error", (err, response) -> done(err, job)

