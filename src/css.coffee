# returns generator
# get a bison grammar for css, learn how to use jison, bam

{parse} = require './grammars/css.tab'

# use for testing grammar
# listener = (line) -> console.log parse line.toString().trim()
# process.stdin.on 'data', listener
# process.stdin.on 'end', -> process.stdin.removeListener 'data', listener
