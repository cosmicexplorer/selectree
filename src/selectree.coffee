stream = require 'stream'
_ = require 'lodash'
util = require './util'
ParseCSS = require('./grammars/css.tab').parse
ParseXPath = require './xpath'
{SelectStream} = require './streams'

# utility function
StringOrFunOptions = (obj, opts, field) ->
  strOrFun = opts[field]
  return null unless strOrFun?
  noCall = opts.dontFlattenFunctions
  res = switch
    when util.isString strOrFun then obj[strOrFun]
    when util.isFunction strOrFun then strOrFun obj
    else throw new Error "option #{field} not string nor function!"
  if not noCall and util.isFunction res then res() else res

class SelecTree
  # TODO: test class, id
  # optional params: 'xml', 'dontFlattenFunctions', 'class', 'id', 'attributes',
  # 'content'
  # required params for all: 'name'
  # required params for xml: 'children'

  @ValidateArgs: (opts) ->
    if not opts? then throw new Error "no traversal options given!"
    else if not opts.name?
      throw new Error "no 'name' parameter given for object!"
    else if opts.xml and not opts.children?
      throw new Error "no children option given!"

  @EachCaseOfOpts: (obj, opts, arrFun, objFun, valueFun, xmlFun) ->
    if opts.xml or opts.children? then xmlFun? obj, opts
    else
      if util.isArray obj then arrFun obj, opts
      else if util.isObject obj then objFun? obj, opts
      else valueFun? obj, opts

  cloneOpts: -> Object.create @origOpts

  constructor: (@obj, @opts, parent = null) ->
    @constructor.ValidateArgs @opts
    @cachedChildren = null
    # clone opts from original prototype only (root's prototype). don't keep
    # prototype to every parent (memory leak)
    if parent?
      @isRoot = no
      @origOpts = parent.opts
    else
      @isRoot = yes
      @origOpts = @opts

  name: -> if @opts.xml then StringOrFunOptions @obj, @opts, 'name'
  else @opts.name

  class: ->
    if @opts.class?
      StringOrFunOptions @obj, @opts, 'class'
    else @attributes().class

  id: ->
    if @opts.id?
      StringOrFunOptions @obj, @opts, 'id'
    else @attributes().id

  # could use generators here, but things like :nth-last-child() require full
  # enumeration anyway, and most children can fit in memory anyway. streaming
  # trees is a different problem.
  @GetArrayChildren: (thisObj, opts) =>
    obj = thisObj.obj
    obj.map (o, ind) =>
      newOpts = thisObj.cloneOpts()
      newOpts.name = ind.toString()
      new SelecTree o, newOpts, thisObj
  @GetObjectChildren: (thisObj, opts) =>
    obj = thisObj.obj
    for k, v of obj
      newOpts = thisObj.cloneOpts()
      newOpts.name = k
      new SelecTree v, newOpts, thisObj
  @GetEmptyChild: -> []
  children: ->
    # @cachedChildren is maybe a perf boost, but mostly so that we can rely on
    # children always being the same objects each time, which allows us to use
    # weak maps or bloom filters to see if we've already hit the children
    if not @cachedChildren?
      @cachedChildren =
        if @opts.children?
          childrenArr = StringOrFunOptions @obj, @opts, 'children'
          if childrenArr instanceof Array
            childrenArr.map (o) => new SelecTree o, @cloneOpts(), @
          else throw new Error "children not an array!"
        else
          @constructor.EachCaseOfOpts @, @opts,
            @constructor.GetArrayChildren,
            @constructor.GetObjectChildren,
            @constructor.GetEmptyChild
    @cachedChildren

  @GetDefaultContent: (obj, opts) ->
    StringOrFunOptions(obj, opts, 'content') ? null
  content: ->
    @constructor.EachCaseOfOpts @obj, @opts,
      @constructor.GetDefaultContent,
      @constructor.GetDefaultContent,
      (=> @obj),
      @constructor.GetDefaultContent

  attributes: ->
    if @opts.xml or @opts.attributes?
      StringOrFunOptions(@obj, @opts, 'attributes') ? {}
    else @obj

  css: (sel) -> new SelectStream @, sel, ParseCSS
  xpath: (sel) -> new SelectStream @, sel, ParseXPath

# TODO: add tests for fromParents, document the need for a 'parent' field opt
fromParents = (nodesWithParents, opts = {}) ->
  throw new Error "must provide parent field in opts" unless opts.parent?
  objAndParent = nodesWithParents.map (obj) ->
    obj: obj
    parent: StringOrFunOptions obj, opts, 'parent'
  parentObjs = new Map
  root = null
  for node in nodesWithParents
    parent = StringOrFunOptions node, opts, 'parent'
    if not parent?
      if root? then throw new Error "multiple roots (nodes without a parent)"
      else root = node
    else
      prevParent = parentObjs.get parent
      if prevParent? then prevParent.push node
      else parentObjs.set parent, [node]
  finalOpts = Object.create opts
  finalOpts.children = (node) -> parentObjs.get node
  new SelecTree root, finalOpts

# massage input a bit
selectree = (obj, opts = {}) ->
  # selecting the root element, if name not given, can be done with :root in
  # css selectors, and / in XPath
  # making the name blank makes it unselectable by tag name
  opts.name = '' unless opts.xml or opts.name?
  new SelecTree obj, opts

# attach class as property on function
selectree.SelecTree = SelecTree
selectree.fromParents = fromParents

module.exports = selectree
