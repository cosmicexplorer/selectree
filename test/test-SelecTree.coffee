selectree = require '../src/selectree'
{SelecTree} = selectree

module.exports =
  'construction': (test) ->
    test.expect 5
    test.throws (-> new SelecTree {}), "no options"
    test.throws (-> new SelecTree {}, {xml: yes}), "not enough options"
    test.doesNotThrow (-> new SelecTree {xml: yes},
      name: "testName"
      children: "testChildren"
      attributes: "testAttributes"
      content: "testContent"), "enough options given"
    test.throws (-> new SelecTree {}), "no name option"
    test.doesNotThrow (-> new SelecTree {}, {name: "test"}),
      "name given"
    test.done()

  'name': (test) ->
    test.expect 4
    # json only allows direct string name
    jsonName = new SelecTree {}, {name: "test"}
    test.strictEqual jsonName.name(), "test", "json can't find correct name"

    xmlOptsStr =
      xml: yes
      name: 'nameField'
      children: 'childField'
      attributes: 'attrField'
      content: 'contentField'
    xmlNameString = new SelecTree {nameField: 'test'}, xmlOptsStr
    test.strictEqual xmlNameString.name(), "test", "xml can't find string name"

    xmlOptsFun = Object.create xmlOptsStr
    xmlOptsFun.name = (obj) -> obj.nameField
    xmlNameFun = new SelecTree {nameField: 'test'}, xmlOptsFun
    test.strictEqual xmlNameFun.name(), "test", "xml can't find function name"

    xmlNotStringNorFunOpts = Object.create xmlOptsStr
    xmlNotStringNorFunOpts.name = {}
    xmlNotStringNorFunObj = new SelecTree {}, xmlNotStringNorFunOpts
    test.throws (-> xmlNotStringNorFunObj.name()),
      "non-string/function name not throwing"
    test.done()

  'children (json)': (test) ->
    test.expect 9
    opts =
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

  'children (xml)': (test) ->
    test.expect 9
    traversalObj =
      tag: 'root'
      children: [
        {tag: 'leaf', content: 1}
        {tag: 'nonleaf', children: -> [
          {tag: 'leaf', content: 'test'}
          {tag: 'leaf', content: 'hey'}]}]

    stringOpts =
      xml: yes
      name: 'tag'
      children: 'children'
      attributes: 'attrs'
      content: 'content'
    stringObj = new SelecTree traversalObj, stringOpts
    firstChildren = stringObj.children()
    test.equal firstChildren.length, 2, "invalid number of children"
    test.equal firstChildren[0].name(), 'leaf', "invalid child name"
    test.equal firstChildren[0].content(), 1, "invalid child content"
    test.equal firstChildren[1].name(), 'nonleaf', "invalid child name"
    secondChildren = firstChildren[1].children()
    test.equal secondChildren.length, 2, "invalid number of children"
    test.equal secondChildren[0].name(), 'leaf', "invalid child name"
    test.equal secondChildren[0].content(), 'test', "invalid child content"
    test.equal secondChildren[1].name(), 'leaf', "invalid child name"
    test.equal secondChildren[1].content(), 'hey', "invalid child content"
    test.done()

  'function options': (test) ->
    # same as children (xml), but with a function as an option field
    test.expect 9
    traversalObj =
      tag: 'root'
      children: [
        {tag: 'leaf', content: 1}
        {tag: 'nonleaf', children: -> [
          {tag: 'leaf', content: 'test'}
          {tag: 'leaf', content: 'hey'}]}]

    funOpts =
      xml: yes
      name: 'tag'
      children: (obj) -> obj.children
      attributes: 'attrs'
      content: 'content'
    # same with function options
    funObj = new SelecTree traversalObj, funOpts
    firstChildrenFun = funObj.children()
    test.equal firstChildrenFun.length, 2, "invalid number of children"
    test.equal firstChildrenFun[0].name(), 'leaf', "invalid child name"
    test.equal firstChildrenFun[0].content(), 1, "invalid child content"
    test.equal firstChildrenFun[1].name(), 'nonleaf', "invalid child name"
    secondChildrenFun = firstChildrenFun[1].children()
    test.equal secondChildrenFun.length, 2, "invalid number of children"
    test.equal secondChildrenFun[0].name(), 'leaf', "invalid child name"
    test.equal secondChildrenFun[0].content(), 'test', "invalid child content"
    test.equal secondChildrenFun[1].name(), 'leaf', "invalid child name"
    test.equal secondChildrenFun[1].content(), 'hey', "invalid child content"
    test.done()

  'dontFlattenFunctions': (test) ->
    test.expect 2
    f = -> 'test'
    obj = content: f

    flattenOpts =
      xml: yes
      name: 'test'
      children: 'test'
      attributes: 'test'
      content: 'content'
    flattenObj = new SelecTree obj, flattenOpts
    test.equal flattenObj.content(), 'test', "invalid flattened result"

    nonFlatOpts = Object.create flattenOpts
    nonFlatOpts.dontFlattenFunctions = yes
    nonFlatObj = new SelecTree obj, nonFlatOpts
    test.equal nonFlatObj.content(), f, "invalid non-flattened result"
    test.done()

  'attributes (json)': (test) ->
    test.expect 1
    obj =
      a: 1
      b: 2
    tree = new SelecTree obj, {name: 'base'}
    test.deepEqual tree.attributes(), obj, "invalid attributes"
    test.done()

  'attributes (xml)': (test) ->
    test.expect 2
    opts =
      xml: yes
      name: 'test',
      children: 'test',
      attributes: 'attrs',
      content: test

    emptyAttributes = {}
    emptyAttrsTree = new SelecTree emptyAttributes, opts
    test.deepEqual emptyAttrsTree.attributes(), {}, "invalid empty attributes"

    testKVPairs = {a: 1, b: 2}
    normalAttrs = attrs: testKVPairs
    normalAttrsTree = new SelecTree normalAttrs, opts
    test.deepEqual normalAttrsTree.attributes(), testKVPairs,
      "invalid normal attributes"
    test.done()

  'cachedChildren': (test) ->
    test.expect 2
    testObj = a: [2, 3]
    tree = selectree(testObj)
    test.strictEqual tree.cachedChildren, null
    children = tree.children()
    test.strictEqual tree.children(), children
    test.done()
