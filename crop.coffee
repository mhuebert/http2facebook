fs = require('fs')
gm = require("gm").subClass({ imageMagick: true })
path = require("path")

buffer = fs.readFileSync(path.join __dirname, '10498258_1446538872289694_7366729534756156923_o.jpg') 
gm(buffer).size (err, size) ->
  console.log size
  numPages = Math.ceil size.height / 800
  for i in [0..(numPages-1)]
    do (i ) ->
      gm(buffer).noop().crop(size.width, 810, 0, (790*i)).write("./img#{i}.jpg", -> console.log arguments)
  # .write "./img%d.jpg", ->
  #   console.log arguments
# 