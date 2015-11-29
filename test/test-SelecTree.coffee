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
    test.strictEqual jsonName.name(), "test", "json can't find correct name"

    xmlOptsStr =
      name: 'nameField'
      children: 'childField'
      attributes: 'attrField'
      content: 'contentField'
    xmlNameString = new SelecTree {nameField: 'test'}, xmlOptsStr
    test.strictEqual xmlNameString.name(), "test", "xml can't find string name"

    xmlOptsFun = SelecTree.CloneOpts xmlOptsStr
    xmlOptsFun.name = (obj) -> obj.nameField
    xmlNameFun = new SelecTree {nameField: 'test'}, xmlOptsFun
    test.strictEqual xmlNameFun.name(), "test", "xml can't find function name"

    xmlNotStringNorFunOpts = SelecTree.CloneOpts xmlOptsStr
    xmlNotStringNorFunOpts.name = {}
    xmlNotStringNorFunObj = new SelecTree {}, xmlNotStringNorFunOpts
    test.throws (-> xmlNotStringNorFunObj.name()),
      "non-string/function name not throwing"
    test.done()

  'SelecTree-GetChildrenJson': (test) ->
    test.expect 9
    opts =
      json: yes
      name: "base"

    jsonBaseType = null
    jsonBaseTree = new SelecTree jsonBaseType, opts
    test.deepEqual jsonBaseTree.children(), [], "null object not empty children"

    jsonArrayType = ['hey']
    jsonArrayTree = new SelecTree jsonArrayType, opts
    arrayRes = jsonArrayTree.children()
    test.equal arrayRes.length, 1, "array object has invalid number of children"
    test.equal arrayRes[0].name(), '0', "array child has invalid name"
    test.equal arrayRes[0].obj, 'hey', "array child has invalid value"

    jsonObjectType = {hey: 'ya', hello: 'hey'}
    jsonObjectTree = new SelecTree jsonObjectType, opts
    objectRes = jsonObjectTree.children()
    test.equal objectRes.length, 2, "object has invalid number of children"
    test.equal objectRes[0].name(), 'hey', "object child has invalid name"
    test.equal objectRes[0].obj, 'ya', "object child has invalid value"
    test.equal objectRes[1].name(), 'hello', "object child has invalid name"
    test.equal objectRes[1].obj, 'hey', "object child has invalid value"
    test.done()
