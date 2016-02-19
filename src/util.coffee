class InternalError extends Error
  constructor: (msg) ->
    super "internal error: #{msg}"

# adds property=value to obj, or property=condition()
addProp = (obj, prop, valOrCondition = yes) ->
  obj[prop] =
    if (valOrCondition instanceof Function)
      if valOrCondition() then yes else no
    else if valOrCondition? then valOrCondition
    else yes
  obj

module.exports = {
  InternalError
  addProp
}
