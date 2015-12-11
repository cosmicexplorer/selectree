{parse: parseCSS} = require '../src/grammars/css.tab'
{match} = require '../src/tree-walker'
selectree = require '../src/selectree'

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    obj =
      k:
        b:
          a: [null, 4]
        c: '3'
      l: 57
      a: 2
    gen = match selectree(obj), parseCSS('a > 1, :root > a')
    test.deepEqual Array.from(gen).map((node) -> node.content()), [4, 2]
    test.done()
