`function* flatMap(gen, fn) {
  for (let el of gen) {
    yield*(fn(el));
  }
}`

`function* filter(gen, fn) {
  for (let el of gen) {
    if (fn(el)) {
      yield(el);
    }
  }
}`

getChildrenAndIndex = (node) ->
  p = node.parent()
  if p
    children = p.children()
    [children, (children.findIndex (el) -> el.id() is node.id())]
  else null

module.exports = {flatMap, filter, getChildrenAndIndex}
