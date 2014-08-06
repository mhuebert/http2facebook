fs = require('fs')
gm = require("gm").subClass({ imageMagick: true })
path = require("path")

addSuffix = (path, suffix) ->
  path[0..-5] + "-" + suffix + path[-4..-1]
insert = (string, toInsert, index) ->
  if index > 0
    string.substring(0, index) + toInsert + string.substring(index, string.length)
  else
    toInsert + string

module.exports = (job, done) ->
  buffer = fs.readFileSync(job.imagePath) 
  gm(buffer).size (err, size) ->
    numImages = Math.ceil size.height / 800

    if numImages == 1
      job.imagePaths = []
      return done(null, job)

    imagePaths = []
    imageFinishedCount = 0

    count = ->
      imageFinishedCount += 1
      if imageFinishedCount == numImages
        job.imagePaths = imagePaths
        done(null, job)

    for i in [0..(numImages-1)]
      iPath = addSuffix(job.imagePath, i)
      imagePaths.push iPath
      do (i, iPath) ->
        gm(buffer)
          .crop(size.width, 810, 0, (790*i))
          .write(iPath, -> count())