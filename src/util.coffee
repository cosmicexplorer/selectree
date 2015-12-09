isString = (obj) -> obj instanceof String or typeof obj is 'string'
isFunction = (obj) -> obj instanceof Function
isArray = (obj) -> obj instanceof Array
isObject = (obj) -> obj instanceof Object

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
  isString
  isFunction
  isArray
  isObject
  InternalError
  addProp
}
