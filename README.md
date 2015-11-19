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

Options will allow for static objects as well as streams.

If "XML" in options is truthy:
- Need "tagName" field for selection.
- If "attribute" field given, then selectree will check that field for any attributes at the current node (the "attributes" field should be an associative object).
- If "children" is given, then selectree will check that attribute to get child nodes of the current node.
