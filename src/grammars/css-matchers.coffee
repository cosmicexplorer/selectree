# drawn from http://www.w3.org/TR/css3-selectors/#selectors

_ = require 'lodash'
util = require '../util'
matchFuns = require '../match'

# tag names
element = (str) -> switch str
  when '*' then (child) -> yield child
  else (child) -> if child.name() is str then yield child else null

# turns functions of type (attr) -> to type (child) ->
getAttributeMacro = (ident, f) -> (child) ->
  f child.attributes()[ident]?.toString()
attributeExists = (ident) -> getAttributeMacro ident, (attr) -> attr?

attributeEqualMap =
  '=': (attr, idOrString, caseFold) ->
    if caseFold then attr.toLowerCase() is idOrString.toLowerCase()
    else attr is idOrString
  '*=': (attr, idOrString, caseFold) ->
    if caseFold
      attr.toLowerCase().indexOf(idOrString.toLowerCase()) isnt -1
    else attr.indexOf(idOrString) isnt -1
attributeMatchMap =
  '~=': (attr, escapedValue, flags) ->
    attr.match(new RegExp "(^|\\s)#{escapedValue}($|\\s)", flags)?
  '^=': (attr, escapedValue, flags) ->
    attr.match(new RegExp "^#{escapedValue}", flags)?
  '$=': (attr, escapedValue, flags) ->
    attr.match(new RegExp "#{escapedValue}$", flags)?
  '|=': (attr, escapedValue, flags) ->
    attr.match(new RegExp "^#{escapedValue}(\\-)?", flags)?

attributeMatch = (ident, attribMatch, caseInsensitive, idOrString) ->
  caseFold = caseInsensitive isnt ''
  equalAttrib = attributeEqualMap[attribMatch]
  matchAttrib = attributeMatchMap[attribMatch]
  getAttributeMacro ident,
    if equalAttrib? then (attr) -> equalAttrib attr, idOrString, caseFold
    else if matchAttrib?
      flags = if caseFold then "g" else "gi"
      escapedId = _.escapeRegExp idOrString
      (attr) -> matchAttrib attr, escapedId, flags
    else throw new Error "unrecognized attribute matcher #{attribMatch}"

idSelector = (id) -> (child) -> child.id() is id
classSelector = (classSel) -> (child) ->
  attributeMatchMap['~='] child.class(), _.escapeRegExp classSel

getIndexMacro = (f) -> (child) ->
  [children, index] = util.getChildrenAndIndex child
  f children, index

pseudoClassMap =
  'root': (child) -> child.isRoot
  'first-child': getIndexMacro (children, index) -> index is 0
  'last-child': getIndexMacro (children, index) -> index is children.length - 1
  'first-of-type': getIndexMacro (children, index) ->
    type = children[index].name()
    ind = 0
    while ind < index
      return false if children[ind].name() is type
    return true
  'last-of-type': getIndexMacro (children, index) ->
    type = children[index].name()
    ind = children.length - 1
    while ind > index
      return false if children[ind].name() is type
    return true
  'only-child': getIndexMacro (children, index) -> children.length is 1
  'only-of-type': getIndexMacro (children, index) ->
    type = children[index].name()
    for child, i in children
      return false if i isnt index and child.name() is type
    return true
  'empty': (child) -> child.children().length is 0

pseudoClass = (pclass) ->
  pseudoClassMap[pclass] ?
    throw new Error "unrecognized pseudo class #{pclass}"

functionalPseudoClassMap =
  # +1 is because indexing is 1-based
  'nth-child': (children, index, recognizer) -> recognizer(index + 1)
  'nth-last-child': (children, index, recognizer) ->
    recognizer(children.length - index)
  # +1 is because indexing is 1-based
  'nth-of-type': (children, index, recognizer) ->
    current = children[index]
    type = current.name()
    ind = 0
    for child, i in children.filter((c) -> c.name() is type)
      if child is current
        ind = i
        break
    recognizer(ind + 1)
  'nth-last-of-type': (children, index, recognizer) ->
    current = children[index]
    type = current.name()
    filtered = children.filter (c) -> c.name() is type
    ind = filtered.length - 1
    for child, i in filtered
      if child is current
        ind = i
        break
    recognizer(filtered.length - ind)

parseA_N_Plus_BExpr = (expr) ->
  match = expr.match(/^([-+]?[0-9]*[nN])?([-+]?[0-9]+)?$/i)
  if not match? then throw new Error "incorrect lex of an+b expr '#{expr}'"
  multipleStr = match[1]
  multiple = if not multipleStr? then null else switch multipleStr
    when '-' then -1
    when '' then 1
    else parseInt multipleMatch[1]
  offsetMatch = match[2]
  offset = if offsetMatch then parseInt offsetMatch else 0
  if (not multiple?) and (offset is 0)
    throw new Error "nth-* indices start at 1"
  if multiple?
    if multiple > 0
      (num) ->
        res = num - offset
        if res < 0 then no
        else res %% multiple is 0
    else
      (num) ->
        res = num - offset
        if res > 0 then no
        else -(res) %% (-multiple) is 0
  else (num) -> num is offset

# these don't NEED to be immediately-invoked functions, but everything else is
parseOddExpr = -> (num) -> num % 2 is 1
parseEvenExpr = -> (num) -> num % 2 is 0

functionalPseudoClass = (pclass, recognizer) ->
  fn = functionalPseudoClassMap[pclass] ?
    throw new Error "unrecognized functional pseudo class #{pclass}"
  getIndexMacro (children, index) -> fn children, index, recognizer

pseudoElement = (el) ->
  throw new Error "pseudo-elements (#{el}) are not supported"

# combinators
combinatorMap =
  'descendant': matchFuns.descendant
  '>': matchFuns.childMatcher
  '~': matchFuns.sibling
  '+': matchFuns.neighbor

doCombination = (matcher, next) -> combinatorMap[next.comb] matcher, next.seq

module.exports = {
  element
  attributeExists
  attributeMatch
  idSelector
  classSelector
  pseudoClass
  parseA_N_Plus_BExpr
  parseEvenExpr
  parseOddExpr
  functionalPseudoClass
  pseudoElement
  doCombination
}
