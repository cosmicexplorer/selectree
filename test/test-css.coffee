_ = require 'lodash'
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
    test.expect 1
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
  'paths': (test) ->
    test.expect 1
    obj = a: [5]
    gen = match selectree(obj), parseCSS('a > 0')
    res = Array.from(gen).map((node) -> node.path)
    test.deepEqual res, ['/root/a/0']
    test.done()
  'attributes': (test) ->
    test.expect 2
    obj = a: [7]
    gen = match selectree(obj), parseCSS('[0]')
    res = Array.from(gen).map((node) -> node.path)
    test.deepEqual res, ['/root/a']
    gen = match selectree(obj), parseCSS('[0=7]')
    res = Array.from(gen).map((node) -> node.attributes()[0])
    test.deepEqual res, [7]
    test.done()
  'pseudo': (test) ->
    test.expect 2
    obj = [3, 5, 1]
    gen = match selectree(obj), parseCSS(':not(:root):first-child')
    res = Array.from(gen).map((node) -> node.path)
    test.deepEqual res, ['/root/0']
    obj = [{n: 1, t: 1}, {n: 2, t: 1}]
    cnt = 0
    tree = selectree obj,
      xml: yes
      name: (obj) -> obj.get().t ? 'root'
      content: (obj) -> obj.get().n
      children: (obj) ->
        res = obj.get()
        if _.isArray res then res
        else []
      id: (obj) -> cnt++
    gen = match tree, parseCSS(':nth-of-type(2)')
    res = Array.from(gen).map((node) -> node.content())
    test.deepEqual res, [2]
    test.done()
  'comma': (test) ->
    test.expect 1
    obj =
      a: 1
      b: 3
      c: [5]
    gen = match selectree(obj), parseCSS('a, c > 0')
    res = Array.from(gen).map((node) -> node.content())
    test.deepEqual res, [1, 5]
    test.done()
  'toNodes': (test) ->
    test.expect 1
    test.deepEqual Array.from(selectree({a: [3, 4]}).css('a > *')), [3, 4]
    test.done()
