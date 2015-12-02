selectree
=========

A wrapper that takes your tree-like data structure and makes CSS/XPath selectors available for traversal.

Usage:
``` javascript
var selectree = require('selectree');
// optional options object as second argument
selectree(treeLikeObject).css('field1 > field2[attribute="value"]', function(node) {
  // do something
});
```

If no options argument given, assume object is a normal javascript object (JSON-like) and select on that (no "attributes" allowed, just children and node names). Returns node stream (available through browserify!) from `.css()` and `.xpath()` calls.

Unless `json` in options is truthy:
- Need `name` field for selection.
- If `attribute` field given, then selectree will check that field for any attributes at the current node (the `attributes` field should be an associative object).
- If `children` is given, then selectree will check that attribute to get child nodes of the current node.

# TODO

- Make some function that allows piping the output of a selection into a new object stream (by making `.css()`/`.xpath()` a Readable stream). Something like:

``` javascript
selectree(treeLikeObj)
  .css('field1 > field2')
  .pipe(otherStreamWhichLikesObjects);
```

- We should make the above and below work so that:
  - the selector functions `.css()`/`.xpath()` return a *newly-created* `Readable` stream
  - select funs accept an optional second argument; a function which receives the node the selector selects on, and returns a modified version of that node. in the output stream, the selected nodes will be replaced with the output
  - the output `Transform` stream will have a `toTree()` function accepting a callback which runs on completion of the stream

- Allow modification of the tree and piping into another object (the first tree-like object, but with whatever modifications you may have made). Something like:

``` javascript
selectree(treeLikeObj)
  .css('field1 > field2', function(node) {
    node.tagName = "field3";
    return node;
  }).toTree(function(tree) {
    console.log(tree);
  });
```

- Make sure to do all readableStream event creation by pushing onto the event queue instead of doing synchronously, otherwise you get a synchronous stream, which is just silly.
- Along the same lines, consider some sort of modification that allows stream-based input instead of requiring a physical object.

# LICENSE

[GPLv3](GPL.md)
