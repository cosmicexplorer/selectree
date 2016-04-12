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
    if not noCall and _.isFunction obj[strOrFun] then obj[strOrFun]()
    else obj[strOrFun]
  else if _.isFunction strOrFun
    res = strOrFun obj
    if not noCall and _.isFunction res then res() else res
  else throw new Error "option #{field} not string nor function!"

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
    ret = if opts.xml then xmlFun? obj, opts
    else if _.isArray obj.obj then arrFun? obj, opts
    else if _.isObject obj.obj then objFun? obj, opts
    else valueFun? obj, opts
    ret ? []

  cloneOpts: -> Object.create @origOpts

  constructor: (@obj, @opts, @parentSel = null, prevPath = '') ->
    @constructor.ValidateArgs @opts
    @cachedChildren = null
    # clone opts from original prototype only (root's prototype). don't keep
    # prototype to every parent (memory leak)
    if @parentSel?
      @isRoot = no
      @origOpts = @parentSel.opts
      @path = "#{prevPath}/#{@name()}"
    else
      @isRoot = yes
      @origOpts = @opts
      @path = "#{@name()}"

  name: ->
    if @opts.xml then StringOrFunOptions @obj, @opts, 'name'
    else @opts.name

  class: ->
    if @opts.class? then StringOrFunOptions @obj, @opts, 'class'
    else @attributes().class

  id: ->
    if @opts.id? then StringOrFunOptions @obj, @opts, 'id'
    else if @opts.xml then @attributes().id
    else @path

  # FIXME: deal with variation in .children() by subclassing
  # could use generators here, but things like :nth-last-child() require full
  # enumeration anyway, and most children can fit in memory anyway. streaming
  # trees is a different problem.
  @GetArrayChildren: (thisObj, opts) =>
    obj = thisObj.obj
    obj.map (o, ind) =>
      newOpts = thisObj.cloneOpts()
      newOpts.name = ind.toString()
      new SelecTree o, newOpts, thisObj, thisObj.path
  @GetObjectChildren: (thisObj, opts) =>
    obj = thisObj.obj
    for k, v of obj
      newOpts = thisObj.cloneOpts()
      newOpts.name = k
      new SelecTree v, newOpts, thisObj, thisObj.path
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
            childrenArr.map (o) => new SelecTree o, @cloneOpts(), @, @path
          else throw new Error "children not an array!"
        else
          debugger
          @constructor.EachCaseOfOpts @, @opts,
            @constructor.GetArrayChildren,
            @constructor.GetObjectChildren,
            @constructor.GetEmptyChild
    @cachedChildren

  parent: -> @parentSel

  @GetDefaultContent: (obj, opts) -> StringOrFunOptions(obj.obj, opts, 'content')
  content: ->
    @constructor.EachCaseOfOpts @, @opts,
      @constructor.GetDefaultContent,
      @constructor.GetDefaultContent,
      (=> @obj),
      @constructor.GetDefaultContent

  attributes: ->
    if @opts.xml or @opts.attributes?
      StringOrFunOptions(@obj, @opts, 'attributes') ? {}
    else @obj

  css: (sel) -> match @, parseCSS(sel)
  # xpath: (sel) -> match @, parseXPath(sel)

  get: -> @obj

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
