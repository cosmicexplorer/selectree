{parse: parseCSS} = require '../src/grammars/css.tab'
{match} = require '../src/tree-walker'
selectree = require '../src/selectree'

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    obj =
      k:
        b:
          a: 4
      l: 57
      a: 2
    # TODO: de-dup results, using bloom filters or weak maps or just maps
    gen = match selectree(obj), parseCSS('k b a, a')
    res = Array.from(gen).map (node) -> node.content()
    test.deepEqual res, [4, 2], 'oops!'
    test.done()
