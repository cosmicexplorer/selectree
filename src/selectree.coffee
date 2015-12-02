stream = require 'stream'
ParseCSS = require './engines/css'
ParseXPath = require './engines/xpath'
{SelectStream} = require './streams'

class SelecTree
  @OptionalParams: ['json', 'dontFlattenFunctions']
  @Params: ['name', 'children', 'attributes', 'content']

  @ValidateArgs: (opts) ->
    if not opts? then throw new Error "no traversal options given!"
    else if (not opts.json? and
             not @Params.every (p) => opts[p]?)
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
      if obj instanceof Array then arrFun obj, opts
      else if obj instanceof Object then objFun? obj, opts
      else valueFun? obj, opts
    else xmlFun? obj, opts

  @StringOrFunOptions: (obj, opts, field) ->
    strOrFun = opts[field]
    noCall = opts.dontFlattenFunctions
    res = switch strOrFun?.constructor.name
      when 'String' then obj[strOrFun]
      when 'Function' then strOrFun obj
      else throw new Error "option not string nor function!"
    if not noCall and res?.constructor.name is 'Function' then res() else res

  constructor: (@obj, @opts) ->
    @constructor.ValidateArgs @opts

  name: -> if @opts.json then @opts.name
  else @constructor.StringOrFunOptions @obj, @opts, 'name'

  @GetArrayChildren: (obj, opts) => obj.map (o, ind) =>
    newOpts = @CloneOpts opts
    newOpts.name = ind.toString()
    new SelecTree o, newOpts
  @GetObjectChildren: (obj, opts) =>
    for k, v of obj
      newOpts = @CloneOpts opts
      newOpts.name = k
      new SelecTree v, newOpts
  @GetEmptyChild: -> []
  children: ->
    if @opts.children?
      childrenArr = @constructor.StringOrFunOptions @obj, @opts, 'children'
      if childrenArr instanceof Array
        childrenArr.map (o) => new SelecTree o, @opts
      else throw new Error "children not an array!"
    else
      @constructor.EachCaseOfOpts @obj, @opts,
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
  opts.name = 'root' if opts.json and not opts.name?
  return new SelecTree obj, opts

# attach class as property on function
selectree.SelecTree = SelecTree

module.exports = selectree
