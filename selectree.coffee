stream = require 'stream'

class SelecTree
  constructor: (@obj, @opts = {}) ->
    @opts.name ?= (o) -> o.name
    @opts.children ?= (o) -> o.children
    @opts.attributes ?= (o) -> o.attributes

  name: -> @opts.name @obj
  children: -> @opts.children(@obj).map (o) => new SelecTree o, @opts
  attributes: -> @opts.attributes @obj

  # return readable streams
  css: (sel) -> new SelectStream @, sel, {css: yes}
  xpath: (sel) -> new SelectStream @, sel, {xpath: yes}

# returns stateful traversal object with getNext() function
ParseCSS = (obj, sel) ->
ParseXPath = (obj, sel) ->

class SelectStream extends stream.Readable
  constructor: (treeObj, selector, opts = {}) ->
    opts.objectMode = yes
    stream.Readable.call @, opts
    @traverser = if opts.css then ParseCSS treeObj, sel
    else if opts.xpath then ParseXPath treeObj, sel
    else throw new Error "no selector type given!"

  traverse: ->
    next = @traverser.getNext() # returns null if at end of tree
    if next? and @push next then process.nextTick => @traverse()

  _read: -> process.nextTick => @traverse()

class ToTreeStream extends stream.Writable
  constructor: (opts = {}) ->
