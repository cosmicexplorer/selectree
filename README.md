selectree
=========

A wrapper that takes your tree-like data structure and makes CSS selectors available for traversal.

Usage:
``` javascript
var selectree = require('selectree');
// optional options object as second argument
selectree(treeLikeObject).css('field1 > field2[attribute="value"]', function(node) {
  // do something
});
```

If no options argument given, assume object is a normal javascript object (JSON-like) and select on that (no "attributes" allowed, just children and node names). Returns node stream (available through browserify!) from `.css()` and `.xpath()` calls.

If `xml` in options is truthy:
- Need `name` field for selection.
- If `attribute` field given, then selectree will check that field for any attributes at the current node (the `attributes` field should be an associative object).
- If `children` is given, then selectree will check that attribute to get child nodes of the current node.

# TODO
- xpath or graphql?
    - we'll see, those take a while to implement and are harder to generalize
    - xpath sounds cool though we'll see
        - *update:* the xpath implementation is maybe 25% complete

# Links
- [how any json key/value pair can be viewed as an index into an entity](https://cloud.google.com/blog/products/application-development/api-design-why-you-should-use-links-not-keys-to-represent-relationships-in-apis)
    - *this results in an equivalence between attributes (key/value pairs) and sub-objects (key/object pairs)!!!*
        1. **this means we have a way to specify attribute accesses in the same syntax as we do traversal of sub-objects**
        2. *TODO: we can use this to formally prove the json <=> xml equivalence*
            - probably not too hard to do!!!

# LICENSE

[GPLv3](GPL.md)
