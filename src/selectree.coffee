stream = require 'stream'

class SelecTree
  @RequiredParams: ['name', 'children', 'attributes', 'content']
  @ValidateArgs: (opts) ->
    # this branch should never be taken in user code
    if not opts? then throw new Error "no traversal options given!"
    else if (not opts.json? and
             not @RequiredParams.every (p) => opts[p]?)
      throw new Error "not all traversal options [#{@RequiredParams.join ','}]
        given!"
    else if opts.json? and not opts.name?
      throw new Error "no 'name' parameter given for json object!"
  @CloneOpts: (opts) ->
    newOpts = {}
    newOpts[param] = opts[param] for param in @constructor.RequiredParams
    newOpts
  @EachCaseOfOpts: (obj, opts, arrFun, objFun, jsonFun, xmlFun) ->
    if opts.json and not opts.children?
      if obj instanceof Array then arrFun obj, opts
      else if obj instanceof Object then objFun obj, opts
      else jsonFun obj, opts
    else xmlFun obj, opts

  constructor: (@obj, @opts) ->
    @constructor.ValidateArgs @opts

  name: -> if @opts.json then @opts.name else @opts.name @obj

  # if element has no children (.children() returns an empty array), then the
  # element may have "content," similar to a text node in HTML. for self-closing
  # (empty) tags, or nodes which have an open and close tag but nothing in
  # between, this will be zero. "content" may contain absolutely anything
  # 'attributes' is provided as a string for json-like objects, just like name
  @GetArrayChildren: (obj, opts) => obj.map (o, ind) =>
    newOpts = @CloneOpts opts
    newOpts.name = ind.toString()
    new SelecTree o, newOpts
  @GetObjectChildren: (obj, opts) =>
    attrs = opts.attributes
    for k, v of obj
      if k is attrs then continue
      newOpts = @CloneOpts opts
      newOpts.name = k
      new SelecTree v, newOpts
  @GetEmptyChild: -> []
  @GetXmlChildren: (obj, opts) ->
    opts.children(obj).map (o) => new SelecTree o, opts
  children: ->
    @constructor.EachCaseOfOpts @obj, @opts,
      @constructor.GetArrayChildren,
      @constructor.GetObjectChildren,
      @constructor.GetEmptyChild,
      @constructor.GetXmlChildren

  @GetEmptyContent: -> ''
  content: ->
    @constructor.EachCaseOfOpts @obj, @opts,
      @constructor.GetEmptyContent,
      @constructor.GetEmptyContent,
      (=> @obj),
      @opts.content

  attributes: -> @opts.attributes? @obj

  # return readable streams
  css: (sel) -> new SelectStream @, sel, ParseCSS
  xpath: (sel) -> new SelectStream @, sel, ParseXPath

# returns stateful traversal object with getNext() function
ParseCSS = (obj, sel) ->
ParseXPath = (obj, sel) ->

class SelectStream extends stream.Readable
  constructor: (treeObj, selector, traverseFun, opts = {}) ->
    opts.objectMode = yes
    stream.Readable.call @, opts
    @traverser = traverseFun treeObj, selector

  traverse: ->
    next = @traverser.getNext() # returns null if at end of tree
    if next? and @push next then process.nextTick => @traverse()

  _read: -> process.nextTick => @traverse()

class ToTreeStream extends stream.Writable
  constructor: (opts = {}) ->

module.exports = {
  SelecTree
}
