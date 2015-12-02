isString = (obj) -> obj instanceof String or typeof obj is 'string'
isFunction = (obj) -> obj instanceof Function
isArray = (obj) -> obj instanceof Array
isObject = (obj) -> obj instanceof Object

module.exports = {
  isString
  isFunction
  isArray
  isObject
}
