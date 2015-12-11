{parse: parseCSS} = require '../src/grammars/css.tab'
{match} = require '../src/tree-walker'
selectree = require '../src/selectree'

# FIXME: allow selecting on the type of json object
# add as attribute on selectree object: [type="array"] maybe?

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    obj =
      k:
        b:
          a: [null, 4]
        c: '3'       # TODO: figure out why this line causes infinite recursion?
      l: 57
      a: 2
    # TODO: figure out why this selector doesn't work!
    gen = match selectree(obj), parseCSS('k b a > *')
    test.deepEqual Array.from(gen).map((node) -> node.content()), [4, 2]
    test.done()
