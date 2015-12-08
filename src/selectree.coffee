stream = require 'stream'
util = require './util'
ParseCSS = require './css'
ParseXPath = require './xpath'
{SelectStream} = require './streams'

# TODO: consider being able to take a list of nodes, each with only a 'parent'
# attribute/function (as an object key or in options object), and transform it
# into a SelecTree as well

class SelecTree
  # TODO: test this
  @OptionalParams: ['json', 'dontFlattenFunctions', 'class', 'id']
  @Params: ['name', 'children', 'attributes', 'content']

  @ValidateArgs: (opts) ->
    if not opts? then throw new Error "no traversal options given!"
    else if (not opts.json? and
             not @Params.every (p) -> opts[p]?)
      errstr = "not all traversal options [#{@Params.join ','}] given!"
      throw new Error errstr
    else if opts.json? and not opts.name?
      throw new Error "no 'name' parameter given for json object!"

  @CloneOpts: (opts) ->
    newOpts = {}
    newOpts[param] = opts[param] for param in @Params
    # one-line version of this is compiling to some weird lambda
    for param in @OptionalParams
      newOpts[param] = opts[param] if opts[param]?
    newOpts

  @EachCaseOfOpts: (obj, opts, arrFun, objFun, valueFun, xmlFun) ->
    if opts.json and not opts.children?
      if util.isArray obj then arrFun obj, opts
      else if util.isObject obj then objFun? obj, opts
      else valueFun? obj, opts
    else xmlFun? obj, opts

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

  name: -> if @opts.json then @opts.name
  else @constructor.StringOrFunOptions @obj, @opts, 'name'

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

  @GetEmptyContent: -> null
  content: ->
    @constructor.EachCaseOfOpts @obj, @opts,
      @constructor.GetEmptyContent,
      @constructor.GetEmptyContent,
      (=> @obj),
      ((obj, opts) => @constructor.StringOrFunOptions obj, opts, 'content')

  attributes: ->
    if @opts.json and not @opts.attributes? then @obj
    else
      res = @constructor.StringOrFunOptions @obj, @opts, 'attributes'
      if res? then res else {}

  css: (sel) -> new SelectStream @, sel, ParseCSS
  xpath: (sel) -> new SelectStream @, sel, ParseXPath

# massage input a bit
selectree = (obj, opts = {}) ->
  # selecting the root element, if name not given, can be done with :root in
  # css selectors, and / in XPath
  # making the name blank makes it unselectable by tag name
  opts.name = '' if opts.json and not opts.name?
  return new SelecTree obj, opts

# attach class as property on function
selectree.SelecTree = SelecTree

module.exports = selectree
