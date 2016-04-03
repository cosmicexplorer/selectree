### factory for tree matching functions

recursively walk tree, adding matchers to list.

start with some start list of matchers. matchers are given a SelecTree node, and
return an object formatted like:
{
  found: <bool>
  childMatcher: <matcher>
}

e.g.:
matcher = (node[, children[, index]]) ->
  found: true
  childMatcher: null

TODO: use absolutePath!
###

# let's make an algebra
createOr = (match1, match2) ->
  if not match1 then match2
  else if not match2 then match1
  else (node, children, index) ->
    {found: leftFound, childMatcher: leftChild} = match1 node, children, index
    {found: rightFound, childMatcher: rightChild} = match2 node, children, index
    found: leftFound or rightFound
    childMatcher: createOr rightChild, leftChild

createAnd = (match1, match2) ->
  if (not match1) or (not match2) then null
  else (node, children, index) ->
    {found: leftFound, childMatcher: leftChild} = match1 node, children, index
    {found: rightFound, childMatcher: rightChild} = match2 node, children, index
    found: leftFound and rightFound
    childMatcher: createAnd rightChild, leftChild

# matcher which accepts everything. progressive
acceptAll = (node, children, index) ->
  found: yes
  childMatcher: acceptAll

infinite = (matcher) -> if not matcher then null else (node, children, index) ->
  {found, childMatcher} = matcher node, children, index
  found: found
  childMatcher: createOr matcher, childMatcher

createNot = (matcher) ->
  if not matcher then acceptAll
  else (node, children, index) ->
    {found, childMatcher} = matcher node, children, index
    found: not found
    childMatcher: createNot childMatcher

# css-like combinators
# >
childMatcher = (match1, match2) ->
  if (not match1) or (not match2) then null
  else (node, children, index) ->
    {found: firstFound, childMatcher: firstNew} = match1 node, children, index
    newSecondMatcher = if firstFound then match2 else null
    newMatcher = createOr (childMatcher firstNew, match2), newSecondMatcher
    found: no
    childMatcher: newMatcher

# space combinator
descendant = (match1, match2) -> childMatcher match1, (infinite match2)

# node is a SelecTree node, matchers are functions as described above
match = (node, matcher) ->
  gen = matchHelper node, [node], 0, matcher, new Set
  yield from gen

# matchSet is a Set used to de-duplicate node results; we use the nodes' ids
# instead of the nodes themselves in a weak set to allow for generated trees
matchHelper = (node, children, index, matcher, idsSeen) ->
  {found, childMatcher} = matcher node, children, index
  id = node.id()
  if found and not idsSeen.has id
    idsSeen.add id
    yield node
  newChildren = node.children()
  for child, ind in newChildren
    yield from matchHelper child, newChildren, ind, childMatcher, idsSeen
  null

module.exports = {
  createOr
  createAnd
  acceptAll
  infinite
  createNot
  match
}
