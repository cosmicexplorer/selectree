selectree
=========

A wrapper that takes your tree-like data structure and makes CSS/XPath selectors available for traversal.

Usage:
```javascript
var selectree = require('selectree');
// optional options object as second argument
selectree(treeLikeObject).css('field1 > field2[attribute=value]')
  .on('data', function(data) {
    // do something
  });
```

If no options argument given, assume object is a normal javascript object (JSON-like) and select on that (no "attributes" allowed, just children and node names). Returns node stream (available through browserify!) from `.css()` and `.xpath()` calls.

If `XML` in options is truthy:
- Need `tagName` field for selection.
- If `attribute` field given, then selectree will check that field for any attributes at the current node (the `attributes` field should be an associative object).
- If `children` is given, then selectree will check that attribute to get child nodes of the current node.

# TODO

1. Make some function that allows piping the output of a selection into a new object stream (essentially making `selectree` a Transform stream). Something like:
``` javascript
selectree(treeLikeObj).css('field1 > field2').pipe(otherStreamWhichLikesObjects);
```

2. Allow modification of the tree and piping into another object (the first tree-like object, but with whatever modifications you may have made). Something like:
``` javascript
var field2To3 = selectree(treeLikeObj).css('field1 > field2', function(node) {
  node.tagName = "field3";
  return node;
}).toTree();
```

3. Make sure to do all readableStream event creation by pushing onto the event queue instead of doing synchronously, otherwise you get a synchronous stream, which is just silly.

4. Along the same lines, consider some sort of modification that allows stream-based input instead of requiring a physical object.

# LICENSE

[GPLv3](GPL.md)
