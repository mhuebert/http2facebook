_ = require("underscore")
@log = (message) ->
  (@value, cb) ->
    console.log message
    cb(null, @value)

@pipeline = pipeline = (value, fns, finished) ->
  console.log "entering pipeline"
  return finished(null, value) if not fns.length
  # console.log "Length is #{fns.length}"

  fns[0] value, (err, response) ->
    # console.log "running fn", _.omit(response, 'stream')
    
    if err == "stop"
      console.log "stopping"
      return finished(response)
    if err
      return finished(err)

    pipeline(response, fns.slice(1), finished)
