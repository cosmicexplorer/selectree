_ = require 'lodash'
{parse: parseCSS} = require './grammars/css.tab'
# ParseXPath = require './xpath'
{match} = require './match'

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

  stringOrFunOptions: (field) ->
    strOrFun = @opts[field]
    return null unless strOrFun
    noCall = @opts.dontFlattenFunctions
    if _.isString strOrFun
      if not noCall and _.isFunction(@obj[strOrFun]) then @obj[strOrFun]()
      else @obj[strOrFun]
    else if _.isFunction strOrFun
      res = strOrFun @
      if not noCall and _.isFunction res then res() else res
    else throw new Error "option #{field} not string nor function!"

  cloneOpts: -> Object.create @opts

  validateOpts: (opts) ->
    throw new Error "no traversal options given" unless opts?

  constructor: (@obj, @opts, @parentTree = null, prevPath = '') ->
    @isRoot = not @parentTree?
    @validateOpts @opts
    @cachedID = null
    @cachedChildren = null
    @cachedContent = null
    @cachedAttributes = null
    @path = "#{prevPath}/#{@name()}"

  name: ->
    @cachedName ?= @stringOrFunOptions('name') ? @getName?()
    @cachedName

  id: ->
    @cachedID ?= @stringOrFunOptions('id') ? @getID?() ? @path
    @cachedID

  children: ->
    if not @cachedChildren?
      res = @stringOrFunOptions 'children'
      @cachedChildren =
        if res? then res.map (o) => SelecTree.MakeTree o, @cloneOpts(), @, @path
        else @getChildren?() ? []
    @cachedChildren

  parent: -> @parentTree

  content: ->
    @cachedContent ?= @stringOrFunOptions('content') ? @getContent?()
    @cachedContent

  attributes: ->
    @cachedAttributes ?=
      @stringOrFunOptions('attributes') ? @getAttributes?() ? {}
    @cachedAttributes

  css: (sel) -> match @, parseCSS(sel)
  # xpath: (sel) -> match @, parseXPath(sel)

  get: -> @obj

class XMLTree extends SelecTree
  validateOpts: (opts) ->
    super(opts)
    throw new Error "no 'name' parameter given" unless opts.name?
    throw new Error "no children option given" unless opts.children?
  constructor: -> super(arguments...)

class JSONTree extends SelecTree
  validateOpts: (opts) ->
    super(opts)
    if (not opts.name?) and (not @isRoot)
      throw new Error "no 'name' parameter for object"
  constructor: -> super(arguments...)
  getID: -> @path
  getName: ->
    if @isRoot then 'root'
    else throw new Error "json name not found"

class JSONArrayTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: -> @obj.map (o, ind) =>
    newOpts = @cloneOpts()
    newOpts.name = do (ind) -> -> ind.toString()
    SelecTree.MakeTree o, newOpts, @, @path
  getContent: -> @obj
  getAttributes: -> @obj

class JSONObjectTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: ->
    for k, v of @obj
      newOpts = @cloneOpts()
      newOpts.name = do (k) -> -> k
      SelecTree.MakeTree v, newOpts, @, @path
  getContent: -> null
  getAttributes: -> @obj

class JSONValueTree extends JSONTree
  constructor: -> super(arguments...)
  getChildren: -> []
  getContent: -> @obj
  getAttributes: -> {}

selectree = (obj, opts = {}) -> SelecTree.MakeTree obj, opts

selectree.SelecTree = SelecTree
selectree.XMLTree = XMLTree
selectree.JSONTree = JSONTree
selectree.JSONArrayTree = JSONArrayTree
selectree.JSONObjectTree = JSONObjectTree
selectree.JSONValueTree = JSONValueTree

module.exports = selectree
