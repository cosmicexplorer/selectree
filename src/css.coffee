# returns stateful traversal object with getNext() function
# get a bison grammar for css, learn how to use jison, bam

{parse} = require './grammars/css.tab'

listener = (line) -> console.log parse line.toString()
process.stdin.on 'data', listener
process.stdin.on 'end', -> process.stdin.removeListener 'data', listener
