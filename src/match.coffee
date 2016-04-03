### factory for tree matching functions

recursively walk tree, adding matchers to list.

start with some start list of matchers. matchers are given a SelecTree node, and
return an object formatted like:
{
  found: <bool>
  child: maybe<matcher>
  next: list<MatcherAndData>
}

e.g.:
matcher = (node) ->
  found: true
  next: null

TODO: use absolutePath!
###

_ = require 'lodash'
util = require './util'

# let's make an algebra
createOr = (match1, match2) ->
  if not match1 then match2
  else if not match2 then match1
  else (node) ->
    yield from match1 node
    yield from match2 node

createAnd = (match1, match2) -> if (not match1) or (not match2) then null
else (node) ->
  leftResults = Array.from (match1 node)
  rightResults = Array.from (match2 node)
  yield from _.intersectionBy [leftResults, rightResults], (el) -> el.id()

infinite = (matcher) -> if not matcher then null else (node) ->
  yield from matcher node
  yield from ((infinite matcher) n) for n in node.children()
  null

# matcher which accepts everything. progressive
acceptAll = infinite (node) -> yield node

createNot = (matcher) -> if not matcher then acceptAll else (node) ->
  matchResults = Array.from (matcher node)
  all = Array.from (acceptAll node)
  yield from _.differenceBy all, matchResults, (el) -> el.id()

# css-like combinators
# >
childMatcher = (match1, match2) -> if (not match1) or (not match2) then null
else (node) ->
  yield from util.flatMap (match1 node), (matched) ->
    yield from (match2 n) for n in matched.children()
    null

# space combinator
descendant = (match1, match2) -> childMatcher match1, (infinite match2)

# +
neighbor = (match1, match2) -> if (not match1) or (not match2) then null
else (node) ->
  yield from util.flatMap (match1 node), (matched) ->
    [children, index] = util.getChildrenAndIndex matched
    next = children[index + 1]
    if next then yield from (match2 next) else null

# ~
sibling = (match1, match2) -> if (not match1) or (not match2) then null
else (node) ->
  yield from util.flatMap (match1 node), (matched) ->
    [children, index] = util.getChildrenAndIndex matched
    if index < children.length - 1
      for i in [(index + 1)..(children.length - 1)]
        yield from (match2 children[i])
    null

# node is a SelecTree node, matchers are functions as described above
match = (node, matcher) ->
  idsSeen = new Set
  yield from util.filter (matcher node), (el) ->
    id = el.id()
    if idsSeen.has id then return no
    else
      idsSeen.add id
      yes

module.exports = {
  createOr
  createAnd
  acceptAll
  infinite
  createNot
  childMatcher
  descendant
  neighbor
  sibling
  match
}
