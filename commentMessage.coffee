module.exports = (time) ->
  mList = [
    "Here you go. Moar!!! #{time}s."
    "Serve you JPG in #{time}s."
    "That was #{time} seconds of work over here."
    "Processing time: #{time} seconds."
    "It was worth spending #{time} seconds on you."
    "#{time} seconds for JPG. JPG!"
    "moar JPG! #{time}s."
    "JPG is the new frontier. #{time} seconds."
    "JPG FTW in #{time}s."
    "Every JPG is one step closer to Internet on Facebook. Processing time: #{time} seconds."
    "peace, love, & jpg. #{time} seconds."
    "#{time} seconds. welcome to the slow web."
    "who needs links when you've got JPG? #{time}s."
    "#{time} seconds is faster than mail-order. Always be grateful."
  ]
  i = Math.floor(Math.random()*(mList.length-1))
  mList[i]
