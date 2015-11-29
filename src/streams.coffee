stream = require 'stream'

class SelectStream extends stream.Readable
  constructor: (treeObj, selector, traverseFun, opts = {}) ->
    opts.objectMode = yes
    stream.Readable.call @, opts
    @traverser = traverseFun treeObj, selector

  traverse: ->
    next = @traverser.getNext() # returns null if at end of tree
    if next? and @push next then process.nextTick => @traverse()

  _read: -> process.nextTick => @traverse()

  toTree: -> new ToTreeStream

class ToTreeStream extends stream.Writable
  constructor: (opts = {}) ->
