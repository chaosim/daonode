{parse} = require "../lib/leftrecursive.js"

xexports = {}

exports.Test =
  "test A: Ax|a; B:A|b": (test) ->
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.equal parse('bxxx'), 'bxxx'
    test.done()
