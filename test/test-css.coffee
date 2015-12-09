{parse: parseCSS} = require '../src/grammars/css.tab'
{match} = require '../src/tree-walker'
selectree = require '../src/selectree'

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    obj =
      k:
        b:
          a: [4]
      l: 57
      a: 2
    aTree = selectree(obj).children()[0].children()[0].children()[0]
    # console.error aTree
    # console.error aTree.children()[0]
    gen = match selectree(obj), parseCSS('a > :nth-child(1), a')
    res = Array.from(gen)
    console.error res
    test.deepEqual res.map((node) -> node.content()), [4, 2], 'oops!'
    test.done()
