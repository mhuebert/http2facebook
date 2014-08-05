_ = require("underscore")

@log = (message) ->
  (@value, cb) ->
    console.log message
    cb(null, @value)

@pipeline = pipeline = (value, fns, finished) ->
  return finished(null, value) if not fns.length
  fns[0] value, (err, response) ->

    if err == "stop"
      return finished(null)
    if err
      return finished(err)

    pipeline(response, fns.slice(1), finished)
