{parse} = require '../src/grammars/css.tab'

module.exports =
  'parseSomething': (test) ->
    test.expect 1
    test.ok parse 'a'
    test.done()
