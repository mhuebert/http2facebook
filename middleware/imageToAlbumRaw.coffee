fs = require('fs')
path = require("path")
sizeOf = require('image-size')
exec = require("child_process").exec

addSuffix = (path, suffix) ->
  path[0..-5] + "-" + suffix + path[-4..-1]
insert = (string, toInsert, index) ->
  if index > 0
    string.substring(0, index) + toInsert + string.substring(index, string.length)
  else
    toInsert + string

module.exports = (job, done) ->
  t1 = Date.now()

  sizeOf job.imagePath, (err, dimensions) ->
    {width, height} = dimensions
    job.imagePaths = []

    maxPages = 40
    pageHeight = 700

    numImages = Math.min (Math.ceil height / pageHeight), maxPages
    # canvasHeight = Math.min height, pageHeight*numImages
    if numImages == 1
      return done(null, job)

    script = "
    convert -crop x#{numImages}+20@ +repage +adjoin #{job.imagePath} #{job.imagePath[0..-5]}_%d.jpg;
    "

    exec script, (err, stdout, stderr) ->
      return done(err, job) if err
      return done(stderr, job) if stderr
      # console.log(stdout)
      for i in [0..(numImages-1)]
        job.imagePaths.push job.imagePath[0..-5]+"_#{i}.jpg"
      console.log "Image paginated in #{Date.now() - t1}"
      done(null, job)