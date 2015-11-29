{SelecTree} = require '../src/selectree'

module.exports =
  # construct SelecTree with empty object to test options validation
  'SelecTree-construction': (test) ->
    test.expect 5
    test.throws (-> new SelecTree {}), "no options"
    test.throws (-> new SelecTree {}, {}), "not enough options"
    test.doesNotThrow (-> new SelecTree {},
      name: "testName"
      children: "testChildren"
      attributes: "testAttributes"
      content: "testContent"), "enough options given"
    test.throws (-> new SelecTree {}, {json: yes}), "no name option"
    test.doesNotThrow (-> new SelecTree {}, {json: yes, name: "test"}),
      "name given"
    test.done()
