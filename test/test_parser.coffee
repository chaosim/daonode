I = require("f:/node-utils/src/importer")

base = "f:/daonode/src/"
I.use base+"solve: Trail, solve, fun, macro vari"
I.use base+"builtins/lisp: begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
I.use base+"builtins/parser: char parsetext settext may any"

xexports = {}

exports.Test =
  "test may char": (test) ->
    test.equal  solve(parsetext(may(char('a')), 'a')), 1
#    test.equal  solve(parsetext(may(char('a')), 'b')), false
    test.done()

  "test may any": (test) ->
    test.equal  solve(parsetext(any(char('a')), 'a')), false
    test.equal  solve(parsetext(any(char('a')), 'aa')), false
    test.equal  solve(parsetext(any(char('a')), 'b')), false
    test.done()

exports.Test =
  "test char": (test) ->
    test.equal  solve(parsetext(char('a'), 'a')), 1
#    test.equal  solve(begin(settext('a'), char('a'))), 1
#    test.equal  solve(parsetext(andp(char('a'), char('b')), 'ab')), 2
    test.done()

