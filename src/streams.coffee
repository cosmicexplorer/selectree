stream = require 'stream'

class SelectStream extends stream.Readable
  constructor: (treeObj, selector, traverseFun, opts = {}) ->
    opts.objectMode = yes
    super opts
    @traverser = traverseFun treeObj, selector

  traverse: ->
    next = @traverser.next()
    if not next.done and @push next.value then process.nextTick => @traverse()

  _read: -> process.nextTick => @traverse()

  toTree: -> new ToTreeStream

class ToTreeStream extends stream.Writable
  constructor: (opts = {}) ->
