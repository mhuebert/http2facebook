module.exports = (time) ->
  mList = [
    "Here you go. Moar!!! #{time}s."
    "Served you JPG Internet in #{time}s."
    "That was #{time} seconds of work over here."
    "Processing time: #{time} seconds."
    "Try drawing a website in #{time} seconds."
    "It was worth spending #{time} seconds on you."
    "#{time} seconds for JPG. JPG!"
    "moar JPG! #{time}s"
    "JPG Internet is the new frontier."
    "JPG FTW"
  ]
  i = Math.floor(Math.random()*(mList.length-1))
  mList[i]
