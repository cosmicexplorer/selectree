_ = require 'lodash'
{parse: parseCSS} = require './grammars/css.tab'
# ParseXPath = require './xpath'
{match} = require './match'

# utility function
StringOrFunOptions = (obj, opts, field) ->
  strOrFun = opts[field]
  return null unless strOrFun?
  noCall = opts.dontFlattenFunctions
  if _.isString strOrFun
    if not noCall and _.isFunction(obj[strOrFun]) then obj[strOrFun]()
    else obj[strOrFun]
  else if _.isFunction strOrFun
    res = strOrFun obj
    if not noCall and _.isFunction res then res() else res
  else throw new Error "option #{field} not string nor function!"

class SelecTree
  # optional: 'xml', 'dontFlattenFunctions', 'id', 'attributes', 'content'
  # required for all: 'name'
  # required for xml: 'children'

  @MakeTree: (obj, opts) ->
    f =
      if opts.xml then XMLTree
      else if _.isArray obj then JSONArrayTree
      else if _.isObject obj then JSONObjectTree
      else JSONValueTree
    new (Function.prototype.bind.call f, {}, arguments...)

  cloneOpts: -> Object.create @opts

  validateOpts: (opts) ->
    throw new Error "no traversal options given" unless opts?
    if (not opts.name?) and (not @isRoot)
      throw new Error "no 'name' parameter given for object"

  constructor: (@obj, @opts, @parentTree = null, prevPath = '') ->
    @isRoot = not @parentTree?
    @validateOpts @opts
    @cachedID = null
    @cachedChildren = null
    @cachedContent = null
    @cachedAttributes = null
    @path = "#{prevPath}/#{@name()}"

  id: ->
    @cachedID ?=
      if @opts.id? then StringOrFunOptions @obj, @opts, 'id'
      else @getID()
    @cachedID

  children: ->
    @cachedChildren ?=
      if @opts.children?
        childrenArr = StringOrFunOptions @obj, @opts, 'children'
        childrenArr.map (o) => SelecTree.MakeTree o, @cloneOpts(), @, @path
      else @getChildren()
    @cachedChildren

  parent: -> @parentTree

  content: ->
    @cachedContent ?=
      if @opts.content? then StringOrFunOptions @obj, @opts, 'content'
      else @getContent()
    @cachedContent

  attributes: ->
    @cachedAttributes ?=
      if @opts.attributes? then StringOrFunOptions(@obj, @opts, 'attributes')
      else @getAttributes()
    @cachedAttributes

  css: (sel) -> match @, parseCSS(sel)
  # xpath: (sel) -> match @, parseXPath(sel)

  get: -> @obj

class XMLTree extends SelecTree
  validateOpts: (opts) ->
    super(opts)
    throw new Error "no children option given" unless opts.children?
  constructor: -> super(arguments...)
  name: -> StringOrFunOptions @obj, @opts, 'name'

class JSONTree extends SelecTree
  constructor: -> super(arguments...)
  getID: -> @path
  name: ->
    res = StringOrFunOptions(@obj, @opts, 'name')
    if res? then res
    else if @isRoot then 'root'
    else throw new Error "json name not found"

class JSONArrayTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: -> @obj.map (o, ind) =>
    newOpts = @cloneOpts()
    newOpts.name = do (ind) -> -> ind.toString()
    SelecTree.MakeTree o, newOpts, @obj, @path
  getContent: -> @obj
  getAttributes: -> {}

class JSONObjectTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: ->
    for k, v of @obj
      newOpts = @cloneOpts()
      newOpts.name = do (k) -> -> k
      SelecTree.MakeTree v, newOpts, @obj, @path
  getContent: -> null
  getAttributes: -> @obj

class JSONValueTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: -> []
  getContent: -> @obj
  getAttributes: -> {}

selectree = (obj, opts = {}) -> SelecTree.MakeTree obj, opts

selectree.SelecTree = SelecTree

module.exports = selectree
