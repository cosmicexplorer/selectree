### factory for tree matching functions

recursively walk tree, adding matchers to list.

start with some start list of matchers. matchers can either return 'yes', 'no',
or another matcher. 'yes' means the match completes, 'no' means it doesn't
match, and another matcher (which could be itself) means the match is in an
intermediate state.

matchers are given (parent, child, childIndex); most matchers will just call
parent.children()[childIndex] to get the current node, but some matchers
(like some css combinators) may need more information. the list of matchers is
then recursively called on all children of all children, etc, in a depth-first
search.

ALL MATCHERS THAT REFERENCE ROOT SHOULD HAVE THE .refersToRoot PROPERTY SET
TRUTHY FOR PERFORMANCE.

when a matcher returns another matcher (intermediate state), that new matcher is
added to a secondary list of new matchers. when any of the new matchers returns
'no', it is removed from that secondary list. none of the original matchers are
ever removed from the normal matcher list.

OPTIMIZATION: if a matcher in the original list fails, and it contains any
reference to a root element, then it should be removed from the original
list. one way to do this is to simply require all matchers which have references
to the root node (absolute paths) to return a new matcher (which as above is
added to a new list), and then remove it from the original list. if no matchers
are left in the original and secondary list, then return from recursive call. if
there are any matchers which query for the root node as a descendant or sibling
of any other node, they are assumed to have been discarded and NOT given to
match.
###

# node is a SelecTree node, matchers are functions as described above
match = (node, origMatchers, secondaryMatchers = []) ->
  for child, index of node.children()
    # refersToRoot MUST be supported by client for performance
    newOrigMatchers =
      if node.isRoot then origMatchers.filter (m) -> not m.refersToRoot
      else origMatchers
    newSecondaryMatchers = []
    for matcher in origMatchers.concat secondaryMatchers
      matchResult = matcher node, child, index
      switch matchResult
        when yes then yield child
        when no
        else newSecondaryMatchers.push matchResult
    # depth-first search
    results = match child, newOrigMatchers, newSecondaryMatchers
    yield res until (res = results.next()).done
  return

module.exports = {
  match
}
