types = ['Boolean', 'Number', 'String', 'Function', 'Array', 'Date', 'RegExp',
  'Undefined', 'Null']

type = do ->
  classToType = {}
  for name in types
    classToType["[object " + name + "]"] = name.toLowerCase()

  (obj) ->
    strType = Object::toString.call(obj)
    classToType[strType] or "object"

isString = (obj) -> 'string' is type obj
isFunction = (obj) -> 'function' is type obj
isArray = (obj) -> 'array' is type obj
isObject = (obj) -> 'object' is type obj

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
  type
  isString
  isFunction
  isArray
  isObject
  InternalError
  addProp
}
