isString = (obj) -> obj instanceof String or typeof obj is 'string'
isFunction = (obj) -> obj instanceof Function
isArray = (obj) -> obj instanceof Array
isObject = (obj) -> obj instanceof Object

class InternalError extends Error
  constructor: (msg) ->
    super "internal error: #{msg}"

module.exports = {
  isString
  isFunction
  isArray
  isObject
}
