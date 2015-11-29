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

  'SelecTree-GetName': (test) ->
    test.expect 4
    # json only allows direct string name
    jsonName = new SelecTree {}, {json: yes, name: "test"}
    test.deepEqual jsonName.name(), "test", "json can't find correct name"

    xmlOptsStr =
      name: 'nameField'
      children: 'childField'
      attributes: 'attrField'
      content: 'contentField'
    xmlNameString = new SelecTree {nameField: 'test'}, xmlOptsStr
    test.deepEqual xmlNameString.name(), "test", "xml can't find string name"

    xmlOptsFun = SelecTree.CloneOpts xmlOptsStr
    xmlOptsFun.name = (obj) -> obj.nameField
    xmlNameFun = new SelecTree {nameField: 'test'}, xmlOptsFun
    test.deepEqual xmlNameFun.name(), "test", "xml can't find function name"

    xmlNotStringNorFunOpts = SelecTree.CloneOpts xmlOptsStr
    xmlNotStringNorFunOpts.name = {}
    xmlNotStringNorFunObj = new SelecTree {}, xmlNotStringNorFunOpts
    test.throws (-> xmlNotStringNorFunObj.name()), "null name not throwing"
    test.done()
