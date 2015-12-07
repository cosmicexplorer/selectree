# drawn from http://www.w3.org/TR/css3-selectors/#selectors

_ = require 'lodash'

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
  'root': getChildIndexMacro (child) -> child.isRoot
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

# this works because the matcher is guaranteed to be a simple matcher; it will
# only return 'yes' or 'no', no intermediate states
negationPseudoClass = (matcher) -> (args...) -> not matcher args...

pseudoClass = (pclass) ->
  pseudoClassMap[pclass] ?
    throw new Error "unrecognized pseudo class #{pclass}"

# TODO: make some an+b/odd/even expression parser
functionalPseudoClass = (pclass, expr) -> switch pclass
  when 'nth-child' then (children, index) -> index
  else throw new Error "unrecognized functional pseudo class #{pclass}"

pseudoElement = (el) ->
  throw new Error "pseudo-elements (#{el}) are not supported"

# combinators
descendant = (matcher1, matcher2) -> (children, index) ->
  if matcher1 children, index
    respawnMatcher2 = (children, index) ->
      res = matcher2 children, index
      if res then res else respawnMatcher2
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
