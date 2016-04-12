{parse: parseCSS} = require '../src/grammars/css.tab'
{match} = require '../src/match'
selectree = require '../src/selectree'

# FIXME: allow selecting on the type of json object
# add as attribute on selectree object: [type="array"] maybe?

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    obj = k: [3]
    matcher = parseCSS(':root > k 0')
    gen = match selectree(obj), matcher
    res = Array.from(gen).map((node) -> node.content())
    test.deepEqual res, [3]
    test.done()
    null
  'nested': (test) ->
    obj =
      k:
        b:
          a: [53, 4]
        c: '3'
      l: 57
      a: 2
    gen = match selectree(obj), parseCSS('k b a > *')
    res = Array.from(gen).map((node) -> node.content())
    test.deepEqual res, [53, 4]
    test.done()
    null
