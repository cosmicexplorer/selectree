stream = require 'stream'
_ = require 'lodash'
util = require './util'
ParseCSS = require('./grammars/css.tab').parse
ParseXPath = require './xpath'
{SelectStream} = require './streams'

class SelecTree
  # TODO: test class, id
  @OptionalParams: ['xml', 'dontFlattenFunctions', 'class', 'id']
  @Params: ['name', 'children', 'attributes', 'content']

  # some form of basic integrity checking, could be improved
  AllParams = @OptionalParams.concat(@Params)
  if AllParams.length > _.uniq(AllParams).length
    throw new util.InternalError "overlapping parameter fields"

  @ValidateArgs: (opts) ->
    if not opts? then throw new Error "no traversal options given!"
    else if opts.xml?
      if (not @Params.every (p) -> opts[p]?)
        throw new Error "not all traversal options [#{@Params.join ','}] given!"
    else if not opts.name?
      throw new Error "no 'name' parameter given for json object!"

  @CloneOpts: (opts) ->
    newOpts = {}
    newOpts[param] = opts[param] for param in @Params
    # one-line version of this is compiling to some weird lambda
    for param in @OptionalParams
      newOpts[param] = opts[param] if opts[param]?
    newOpts

  @EachCaseOfOpts: (obj, opts, arrFun, objFun, valueFun, xmlFun) ->
    if opts.xml or opts.children? then xmlFun? obj, opts
    else
      if util.isArray obj then arrFun obj, opts
      else if util.isObject obj then objFun? obj, opts
      else valueFun? obj, opts

  @StringOrFunOptions: (obj, opts, field) ->
    strOrFun = opts[field]
    noCall = opts.dontFlattenFunctions
    res = switch
      when util.isString strOrFun then obj[strOrFun]
      when util.isFunction strOrFun then strOrFun obj
      else throw new Error "option not string nor function!"
    if not noCall and util.isFunction res then res() else res

  constructor: (@obj, @opts, @parent = null) ->
    @constructor.ValidateArgs @opts
    # TODO: add test for @cachedChildren; ensure they're actually cached
    @cachedChildren = null

  name: -> if @opts.xml then @constructor.StringOrFunOptions @obj, @opts, 'name'
  else @opts.name

  class: ->
    if @opts.class?
      @constructor.StringOrFunOptions @obj, @opts, 'class'
    else @attributes().class

  id: ->
    if @opts.id?
      @constructor.StringOrFunOptions @obj, @opts, 'id'
    else @attributes().id

  parent: -> @parent
  isRoot: -> not @parent?

  # could use generators here, but things like :nth-last-child() require full
  # enumeration anyway, and most children can fit in memory anyway. streaming
  # trees is a different problem.
  @GetArrayChildren: (thisObj, opts) =>
    obj = thisObj.obj
    obj.map (o, ind) =>
      newOpts = @CloneOpts opts
      newOpts.name = ind.toString()
      new SelecTree o, newOpts, thisObj
  @GetObjectChildren: (thisObj, opts) =>
    obj = thisObj.obj
    for k, v of obj
      newOpts = @CloneOpts opts
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
          childrenArr = @constructor.StringOrFunOptions @obj, @opts, 'children'
          if childrenArr instanceof Array
            childrenArr.map (o) => new SelecTree o, @opts, @
          else throw new Error "children not an array!"
        else
          @constructor.EachCaseOfOpts @, @opts,
            @constructor.GetArrayChildren,
            @constructor.GetObjectChildren,
            @constructor.GetEmptyChild
    @cachedChildren

  @GetEmptyContent: -> null
  content: ->
    @constructor.EachCaseOfOpts @obj, @opts,
      @constructor.GetEmptyContent,
      @constructor.GetEmptyContent,
      (=> @obj),
      ((obj, opts) => @constructor.StringOrFunOptions obj, opts, 'content')

  attributes: ->
    if @opts.xml or @opts.attributes?
      res = @constructor.StringOrFunOptions @obj, @opts, 'attributes'
      if res? then res else {}
    else @obj

  css: (sel) -> new SelectStream @, sel, ParseCSS
  xpath: (sel) -> new SelectStream @, sel, ParseXPath

# TODO: consider being able to take a list of nodes, each with a 'parent'
# attribute/function (as an object key or in options object), instead of a
# 'children' attribute/function, and transform it into a SelecTree as well
fromParents = (nodesWithParents, opts = {}) ->
  throw new Error "must provide parent field in opts" if not opts.parent?
  # TODO: continue to write this

# massage input a bit
selectree = (obj, opts = {}) ->
  # selecting the root element, if name not given, can be done with :root in
  # css selectors, and / in XPath
  # making the name blank makes it unselectable by tag name
  opts.name = '' unless opts.xml or opts.name?
  return new SelecTree obj, opts

# attach class as property on function
selectree.SelecTree = SelecTree
selectree.fromParents = fromParents

module.exports = selectree
