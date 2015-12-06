# returns generator
# get a bison grammar for css, learn how to use jison, bam

# use for testing grammar
# {parse} = require './grammars/css.tab'
# listener = (line) -> console.log parse line.toString().trim()
# process.stdin.on 'data', listener
# process.stdin.on 'end', -> process.stdin.removeListener 'data', listener

# combinators
descendant = (matcher1, matcher2) -> (children, index) ->
  if matcher1 children, index
    respawnMatcher2 = (children, index) ->
      res = matcher2 children, index
      if res then res else respawnMatcher2
    respawnMatcher2
  else no

directDescendant = (matcher1, matcher2) -> (children, index) ->
  if matcher1 children, index then matcher2 else no

siblingAfter = (matcher1, matcher2) -> (children, index) ->
  if matcher1(children, index) and index < children.length - 1
    siblingMatcher = (args...) -> matcher2 args...
    siblingMatcher.isForSameSiblings = yes
    siblingMatcher
  else no

siblingImmediatelyAfter = (matcher1, matcher2) -> (children, index) ->
  if matcher1(children, index) and index < children.length - 1
    immediateSiblingMatcher = (args...) -> matcher2 args...
    immediateSiblingMatcher.isForImmediateSibling = yes
    immediateSiblingMatcher
  else no
