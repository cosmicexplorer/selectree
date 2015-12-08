{parse} = require '../src/grammars/css.tab'

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    res = parse 'a'
    console.log res[0].toString()
    test.ok parse 'a'
    test.done()
