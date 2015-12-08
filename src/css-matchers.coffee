# drawn from http://www.w3.org/TR/css3-selectors/#selectors

_ = require 'lodash'
uuid = require 'node-uuid'

# use for testing grammar
# {parse} = require './grammars/css.tab'
# listener = (line) -> console.log parse line.toString().trim()
# process.stdin.on 'data', listener
# process.stdin.on 'end', -> process.stdin.removeListener 'data', listener

# turns functions of type (child) -> to type (children, index) ->
getChildIndexMacro = (f) -> (children, index) -> f children[index]
# tag names
element = (str) ->
  getChildIndexMacro switch str
    when '*' then (child) -> yes
    else (child) -> child.name() is str

# turns functions of type (attr) -> to type (child) ->
getAttributeMacro = (ident, f) -> (child) -> f child.attributes()[ident]
attributeExists = (ident) ->
  getChildIndexMacro getAttributeMacro ident, (attr) -> attr?

attributeEqualMap =
  '=': (attr, idOrString) -> attr is idOrString
  '*=': (attr, idOrString) -> attr?.indexOf(idOrString) isnt -1
attributeMatchMap =
  '~=': (attr, escapedId) -> attr?.match?(new RegExp "\\s#{escapedId}\\s", "g")?
  '^=': (attr, escapedId) -> attr?.match?(new RegExp "^#{escapedId}", "g")?
  '$=': (attr, escapedId) -> attr?.match?(new RegExp "#{escapedId}$", "g")?
  '|=': (attr, escapedId) ->
    attr?.match?(new RegExp "^#{escapedId}(\\-)?$", "g")?

# TODO: allow case-sensitive option during parse creation
attributeMatch = (ident, attribMatch, idOrString) ->
  escapedId = _.escapeRegExp idOrString
  equalAttrib = attributeEqualMap[attribMatch]
  matchAttrib = attributeMatchMap[attribMatch]
  getChildIndexMacro getAttributeMacro ident,
    if equalAttrib? then (attr) -> equalAttrib attr, idOrString
    else if matchAttrib? then (attr) -> matchAttrib attr, escapedId
    else throw new Error "internal error: unrecognized attribute matcher
      #{attribMatch}"

idSelector = (id) -> getChildIndexMacro (child) -> child.id() is id
classSelector = (classSel) -> getChildIndexMacro (child) ->
  attributeMatchMap['~='] child.class(), _.escapeRegExp classSel

pseudoClassMap =
  'root': getChildIndexMacro (child) -> child.isRoot()
  'first-child': (children, index) -> index is 0
  'last-child': (children, index) -> index is children.length - 1
  'first-of-type': (children, index) ->
    type = children[index].name()
    ind = 0
    while ind < index
      return false if children[ind].name() is type
    return true
  'last-of-type': (children, index) ->
    type = children[index].name()
    ind = children.length - 1
    while ind > index
      return false if children[ind].name() is type
    return true
  'only-child': (children, index) -> children.length is 1
  'only-of-type': (children, index) ->
    type = children[index].name()
    for child, i in children
      return false if i isnt index and child.name() is type
    return true
  'empty': getChildIndexMacro (child) -> child.children().length is 0

pseudoClass = (pclass) ->
  pseudoClassMap[pclass] ?
    throw new Error "unrecognized pseudo class #{pclass}"

# this works because the matcher is guaranteed to be a simple matcher; it will
# only return 'yes' or 'no', no intermediate states
negationPseudoClass = (matcher) -> (args...) -> not matcher args...

functionalPseudoClassMap =
  'nth-child': (children, index, recognizer) -> recognizer index
  'nth-last-child': (children, index, recognizer) ->
    recognizer(children.length - index)
  'nth-of-type': (children, index, recognizer) ->
    current = children[index]
    type = current.name()
    index = 0
    for child, i in children.filter((c) -> c.name() is type)
      if child is current
        index = i
        break
    recognizer index
  'nth-last-of-type': (children, index, recognizer) ->
    current = children[index]
    type = current.name()
    filtered = children.filter (c) -> c.name() is type
    index = filtered.length - 1
    for child, i in filtered
      if child is current
        index = i
        break
    recognizer(filtered.length - index)

parseA_N_Plus_BExpr = (expr) ->
  multipleMatch = expr.match(/^((?:\-|\+)?[0-9]+)N/i)?[1]
  multiple = if multipleMatch? then parseInt multipleMatch else 1
  offsetMatch = expr.match(/(?:\-|\+)([0-9]+)$/)?[1]
  offset = if offsetMatch? then parseInt offsetMatch else 0
  (num) ->
    res = num - offset
    if res < 0 then no else res % multiple == 0

parseOddExpr = -> (num) -> num % 2 == 1
parseEvenExpr = -> (num) -> num % 2 == 0

parseFunctionalPseudoClass = (pclass) -> pclass[..-2]

functionalPseudoClass = (pclass, recognizer) ->
  fn = functionalPseudoClassMap[pclass] ?
    throw new Error "unrecognized functional pseudo class #{pclass}"
  (children, index) -> fn children, index, recognizer

pseudoElement = (el) ->
  throw new Error "pseudo-elements (#{el}) are not supported"

combineSimpleSelectorSequence = (matchers) -> (children, index) ->
  for matcher in matchers
    return no unless matcher children, index
  yes

# combinators
descendant = (matcher1, matcher2) ->
  matcherId = uuid.v4()         # for all created descendants, have same id
  (children, index) ->
    if matcher1 children, index
      respawnMatcher2 = (children, index) ->
        res = matcher2 children, index
        # even if matched, still respawn self
        if res then [res, respawnMatcher2] else respawnMatcher2
      respawnMatcher2.matcherId = matcherId
      respawnMatcher2
    else no

directDescendant = (matcher1, matcher2) -> (children, index) ->
  if matcher1 children, index then matcher2 else no

siblingAfter = (matcher1, matcher2) -> (children, index) ->
  if matcher1(children, index) and index < children.length - 1
    siblingMatcher = (args...) -> matcher2 args...
    siblingMatcher.isForSameSiblings = yes
    siblingMatcher
  else no

siblingImmediatelyAfter = (matcher1, matcher2) -> (children, index) ->
  if matcher1(children, index) and index < children.length - 1
    immediateSiblingMatcher = (args...) -> matcher2 args...
    immediateSiblingMatcher.isForImmediateSibling = yes
    immediateSiblingMatcher
  else no

combinatorMap =
  'descendant': descendant
  '>': directDescendant
  '~': siblingAfter
  '+': siblingImmediatelyAfter

doCombination = (simpleSeq, combinatorsArr) ->
  reducer = (matcher, combinatorObj) ->
    combinatorMap[combinatorObj.combinator] matcher, combinatorObj.seq
  combinatorsArr.reduce reducer, simpleSeq

module.exports = {
  element
  attributeExists
  attributeMatch
  idSelector
  classSelector
  pseudoClass
  negationPseudoClass
  parseA_N_Plus_BExpr
  parseEvenExpr
  parseOddExpr
  parseFunctionalPseudoClass
  functionalPseudoClass
  pseudoElement
  combineSimpleSelectorSequence
  doCombination
}
